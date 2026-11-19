# Configuration and use (illustrative, not a one-command deployment)

The actual project ran on Ubuntu in a private EC2 instance. These files are published to explain the implementation, not as a turn-key AWS installer. All AWS resources from the assessment were subsequently cleaned up.

## Required AWS context
- VPC 10.0.0.0/16; bastion in public subnet; app EC2 without public IP in private subnet.
- S3 Gateway Endpoint in the private route table; no permanent NAT.
- EC2 instance role allowing only `s3:PutObject` on `YOUR-BUCKET/backups/*`.
- Private bucket with Block Public Access enabled and same AWS Region as endpoint and Lambda.
- Lambda S3 `ObjectCreated:Put` trigger, prefix `backups/`; DynamoDB table `backup-log` keyed by `backup_id` (String), on-demand.

## Example Linux setup
1. Create `/var/app/data` and arrange for `data-generator.service` in `/etc/systemd/system/`.
2. Save `backup.sh` under `/usr/local/bin/` and make it executable.
3. Configure bucket via a root-readable `/etc/karatu-backup.env`, created from `scripts/karatu-backup.env.example`. Replace its placeholder with your bucket name.
4. Save `backup-cron-wrapper.sh` under `/usr/local/bin/` and make it executable.
5. For the sanitized public template, use the following **example** root cron entry (this wrapper was not part of the original observed deployment):

```cron
*/10 * * * * /usr/bin/bash /usr/local/bin/backup-cron-wrapper.sh
```

The real assessment used `*/10 * * * * /usr/bin/bash /usr/local/bin/backup.sh` with the bucket hard-coded in the original deployed script.

## Safety and limitations
- `/etc/karatu-backup.env` is configuration, not an IAM credential file. Do not store access keys.
- AWS CLI must be installed before removal of the temporary NAT.
- Running the script twice in one minute can overwrite the same S3 key due to minute-resolution filename timestamps.
- `s3:PutObject` without delete is a restriction on the app role, not S3 Object Lock or full immutability.
- `backup_id` uses the S3 key; repeated events for the same key can overwrite its audit item.
- Test restore/retention/monitoring and network design before production use.
