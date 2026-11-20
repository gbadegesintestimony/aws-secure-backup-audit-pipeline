# Troubleshooting and lessons from the lab

## NAT deletion and route blackhole
The private route table displayed a blackhole default route after the temporary NAT Gateway was removed. This was anticipated in the assessment; an active S3 prefix-list route through the Gateway Endpoint still permitted S3 uploads. A failed public `curl` request followed by a successful S3 archive upload demonstrated the distinction.

## Permission verification
An upload-only S3 policy can seem correct in the console but needs testing. The observed `aws s3 rm` operation returned `AccessDenied` for `s3:DeleteObject`, while uploads succeeded.

## Audit verification
A successful S3 upload and a successful DynamoDB audit write are separate outcomes. The lab used matching backup identifiers, DynamoDB table items, and CloudWatch logs to check the complete pipeline.

## DynamoDB schema mismatch: Partition key naming (`backup-id` vs `backup_id`)

### Symptom
S3 backup archives were successfully uploaded by the private EC2 instance, but the `backup-log` DynamoDB audit table remained empty (`Items returned: 0`).

### Diagnosis & logs
Inspecting the Lambda function's log streams (`/aws/lambda/karatu-backup-audit-lambda`) in Amazon CloudWatch revealed the following validation failure:
```text
ClientError: An error occurred (ValidationException) when calling the PutItem operation:
One or more parameter values were invalid: Missing the key backup-id in the item.
```

### Root cause
A naming contract mismatch between the infrastructure definition and the Lambda code:
- The DynamoDB table was originally provisioned with a hyphenated partition key: `backup-id` (String).
- In `lambda_function.py`, the payload dictionary was constructed with an underscore:
  ```python
  'backup_id': {'S': s3_key}
  ```
Because the required primary key `backup-id` was missing from the item dictionary, DynamoDB rejected the `PutItem` API call with a `ValidationException`.

### Resolution
DynamoDB does not allow modifying an existing table's partition key schema in place:
1. Deleted the misconfigured `backup-log` table.
2. Re-created the table with `backup_id` (String) as the primary partition key.
3. Triggered a fresh backup run from the private EC2 instance.
4. Verified that the item was successfully written to DynamoDB and confirmed the CloudWatch audit log:
   ```text
   Audit record created for: backups/backup-2026-11-19-0130.tar.gz
   ```

### Key takeaways
- **Verify behavioral flow, not just resource status:** A green status on a DynamoDB table and successful S3 uploads do not guarantee that the integration contract between them is functioning.
- **Inspect CloudWatch first for silent serverless failures:** Because Lambda runs asynchronously in response to S3 events, failures will fail silently from the caller's perspective without CloudWatch monitoring.

## Bastion SSH access failure: Dynamic client IP reassignment

### Symptom
Attempts to connect to the public bastion host (`44.202.190.63`) via SSH from a local Vagrant environment failed with:
```text
ssh: connect to host 44.202.190.63 port 22: Connection refused
```

### Triage & diagnosis
A systematic check across the networking and compute layers was performed:
1. **EC2 Instance State:** Verified in the AWS EC2 Console that `karatu-bastion-host` (`i-0799e19229185cfa4`) was in `running` state with 2/2 status checks passed.
2. **OS Service Status:** Checked the EC2 System Log to confirm that `sshd` had initialized and was actively listening on port 22.
3. **Network ACLs:** Verified that the subnet's VPC Network ACL (`acl-0dbb9136d5a907733`) correctly allowed inbound and outbound traffic.
4. **Client IP Check:** Ran `curl -s ifconfig.me` from the local terminal to inspect the source public IP.

### Root cause
The local ISP dynamically reassigned the client's public IP address from `41.242.65.170` to `105.127.9.124`. Because the bastion host security group (`karatu-bastion-sg`) was strictly locked down to a single `/32` CIDR rule (`41.242.65.170/32`) following least-privilege principles, the new IP address was blocked at the security group boundary.

### Resolution
1. **Updated Inbound Rule:** Updated the Port 22 SSH ingress rule in `karatu-bastion-sg` to the newly assigned IP: `105.127.9.124/32`.
2. **Reloaded SSH Agent:** Reloaded the keypair into `ssh-agent` (`ssh-add Myweb-kp.pem`) to ensure SSH agent forwarding functioned for the second hop.
3. **Verification:** Reconnected via SSH to the bastion (`44.202.190.63`), then hopped directly to the private application EC2 instance (`10.0.2.47`), confirming end-to-end access was restored.

### Key takeaways
- **Least privilege vs. dynamic IPs:** Restricting management ports to `/32` is an essential cloud security control, but requires updating when operating behind dynamic residential/ISP connections.
- **Layered triage:** Checking compute state (`running`), daemon logs (`sshd`), VPC NACLs, and Security Group rules in sequence isolates network boundary drops from server failure.

## When adapting code
- Bastion SSH connection failed or timed out? Check if your dynamic public IP has changed (`curl -s ifconfig.me`) and update the `/32` ingress rule in the bastion security group.
- Missing `AccessDenied` on delete? Audit effective IAM permissions and bucket policy.
- Upload timeout after NAT removal? Check S3 Gateway Endpoint service, Region, private route table and outbound connectivity.
- Lambda invoked but no audit row? Inspect its CloudWatch logs, `dynamodb:PutItem` permission, table Region/name, and schema attribute casing/hyphenation (e.g., `backup-id` vs `backup_id`).
- Cron not running? Use root's crontab and absolute paths; inspect cron logs.

These are general diagnostic checks. The uploaded evidence does not establish that each listed failure occurred in the actual assessment.
