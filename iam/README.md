# IAM policies (reconstructed templates)

These JSON policy examples are reconstructed from the assessment and visible IAM evidence. They are **not verbatim exports of policies from the deleted AWS account**.

- EC2 backup role: permits `s3:PutObject` under `backups/*` only. No delete or list permission.
- Lambda execution role: permits `dynamodb:PutItem` on `backup-log`, and additionally requires CloudWatch Logs permissions (the assessment used an AWS-managed basic execution policy).
- Lambda must trust the `lambda.amazonaws.com` service principal; EC2 role trusts `ec2.amazonaws.com`.
- The S3 bucket notification must allow S3 to invoke Lambda. That **resource-based invoke permission** is not granted through either IAM policy here.

Replace all `YOUR-...` placeholders before deploying anything.
