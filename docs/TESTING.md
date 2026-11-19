# Test evidence and expected results

The following **observed lab outcomes** come from the uploaded examination screenshots, not from a new deployment.

| Test | Result shown | Supporting evidence |
|---|---|---|
| SSH via bastion | Reached private EC2 | [SSH screenshot](../screenshots/networking/ssh-bastion-hop.png) |
| systemd generator | Service active; timestamps ~30s apart | [status](../screenshots/automation/data-generator-status.png), [log](../screenshots/automation/application-log.png) |
| Cron schedule | Runs backup every 10 minutes | [cron](../screenshots/automation/cron-schedule.png) |
| Restricted deletion | `s3:DeleteObject` denied | [AccessDenied](../screenshots/security/s3-delete-access-denied.png) |
| Backup uploads | Multiple tar.gz objects and backup log success | [S3 listing](../screenshots/automation/s3-backups.png), [log](../screenshots/automation/backup-success-log.png) |
| S3 audit | DynamoDB audit items and Lambda execution logs | [DynamoDB](../screenshots/auditing/dynamodb-backup-records.png), [CloudWatch](../screenshots/auditing/cloudwatch-audit-logs.png) |
| Without NAT | `curl` timed out but backup uploaded successfully | [terminal](../screenshots/verification/natless-curl-failed-s3-upload-succeeded.png) |
| Cleanup | Relevant resources removed | [cleanup screenshots](EVIDENCE_INDEX.md) |

## Local validation of this repository
Run `bash -n scripts/backup.sh scripts/backup-cron-wrapper.sh`; `python -m py_compile lambda/lambda_function.py`; JSON-parse the IAM policy files. These are *syntactic checks*, not live infrastructure integration tests.

## Additional production tests not performed
Recovery/restore drill, integrity verification, monitoring alarms for missing backups, immutability under multiple security principals, stress testing and full redeployment from code.
