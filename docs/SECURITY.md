# Security decisions and boundaries

- **Network isolation:** app EC2 ran in a private subnet without a public IP. SSH arrived via a public-subnet bastion with restricted source IP; the app security group accepted SSH only from the bastion security group.
- **Private S3 access:** an S3 Gateway Endpoint in the private route table allowed S3 data traffic without maintaining a NAT Gateway. The temporary NAT was only for installation and was deleted.
- **Identity:** an instance IAM role, rather than on-disk static credentials, supplied S3 upload authorization.
- **Least privilege:** EC2 policy grants `s3:PutObject` only under `backups/*` and no delete permission. The S3 delete attempt returned `AccessDenied`. Lambda's policy grants `dynamodb:PutItem` for the specific audit table, plus basic CloudWatch Logs via an AWS-managed logging policy.
- **S3 notification permissions:** allowing the S3 service to invoke Lambda is a resource-based Lambda permission separate from the Lambda execution role.

## Limits
The app role's lack of `s3:DeleteObject` **does not make backups immutable** against administrators or other principals. For a real company, evaluate S3 Versioning and Object Lock, appropriate KMS encryption, bucket policies, monitoring, recovery testing, and broader IAM governance. The deployed lab's IAM roles and bucket no longer exist.

Do not commit `.pem`, AWS credentials, `.env` contents, or unreviewed screenshots.
