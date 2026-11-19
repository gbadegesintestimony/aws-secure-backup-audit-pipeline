# Troubleshooting and lessons from the lab

## NAT deletion and route blackhole
The private route table displayed a blackhole default route after the temporary NAT Gateway was removed. This was anticipated in the assessment; an active S3 prefix-list route through the Gateway Endpoint still permitted S3 uploads. A failed public `curl` request followed by a successful S3 archive upload demonstrated the distinction.

## Permission verification
An upload-only S3 policy can seem correct in the console but needs testing. The observed `aws s3 rm` operation returned `AccessDenied` for `s3:DeleteObject`, while uploads succeeded.

## Audit verification
A successful S3 upload and a successful DynamoDB audit write are separate outcomes. The lab used matching backup identifiers, DynamoDB table items, and CloudWatch logs to check the complete pipeline.

## When adapting code
- Missing `AccessDenied` on delete? Audit effective IAM permissions and bucket policy.
- Upload timeout after NAT removal? Check S3 Gateway Endpoint service, Region, private route table and outbound connectivity.
- Lambda invoked but no audit row? Inspect its CloudWatch logs, `dynamodb:PutItem` permission and table Region/name.
- Cron not running? Use root's crontab and absolute paths; inspect cron logs.

These are general diagnostic checks. The uploaded evidence does not establish that each listed failure occurred in the actual assessment.
