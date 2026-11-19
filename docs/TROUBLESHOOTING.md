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

## When adapting code
- Missing `AccessDenied` on delete? Audit effective IAM permissions and bucket policy.
- Upload timeout after NAT removal? Check S3 Gateway Endpoint service, Region, private route table and outbound connectivity.
- Lambda invoked but no audit row? Inspect its CloudWatch logs, `dynamodb:PutItem` permission, table Region/name, and schema attribute casing/hyphenation (e.g., `backup-id` vs `backup_id`).
- Cron not running? Use root's crontab and absolute paths; inspect cron logs.

These are general diagnostic checks. The uploaded evidence does not establish that each listed failure occurred in the actual assessment.
