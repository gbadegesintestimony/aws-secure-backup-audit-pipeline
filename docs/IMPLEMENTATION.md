# Implementation walkthrough

This document explains the **completed lab**, not a one-click deployment. The implementation followed the Karatu 2026 assessment topology and six-stage requirements. The original AWS resources were subsequently removed.

## 1. Network
- Created VPC `10.0.0.0/16` with one public subnet and one private subnet.
- Attached an Internet Gateway and separate route tables.
- Launched bastion EC2 in the public subnet, permitting SSH from a single restricted administrator IP.
- Launched application EC2 with no public IP and SSH limited to the bastion security group.
- Used SSH agent forwarding for bastion-to-private access.
- Created temporary NAT for software installation, then deleted the NAT and released its Elastic IP.
- Associated an S3 Gateway VPC Endpoint with the private route table.

## 2. Storage and instance identity
- Created a private Amazon S3 bucket with Block Public Access enabled.
- Attached an EC2 IAM role allowing only `s3:PutObject` to `backups/*`.
- Tested upload success and an `AccessDenied` error for attempted deletion. No static access keys were required.

## 3. Linux automation
- Installed AWS CLI v2 and required packages while temporary NAT was available.
- Configured `data-generator.service` to append ISO-style timestamps to `/var/app/data/app.log` every 30 seconds.
- Created a Bash backup script using `set -euo pipefail`; it archives `/var/app/data`, uploads it to S3, logs outcomes and deletes local archive after success.
- Scheduled the script in root's crontab every 10 minutes.

## 4. Audit events
- Created DynamoDB table `backup-log` (String partition key `backup_id`, on-demand billing).
- Configured Python Lambda with `dynamodb:PutItem` on that table and CloudWatch Logs permissions.
- Configured S3 PUT notification for prefix `backups/`.
- The Lambda wrote key, object size, event time and bucket for each upload event.

## 5. Verification and cleanup
- Confirmed multiple backup archives and corresponding audit rows.
- Showed failure of `curl -m 5 https://example.com` after NAT deletion and success of a subsequent S3 backup upload.
- Checked CloudWatch invocation logs, created a budget alert and collected evidence.
- Removed project resources after validation to control ongoing charges.

See [screenshots](EVIDENCE_INDEX.md), [validation](VALIDATION.md), and [security](SECURITY.md).
