# Costs and cleanup

The assessment temporarily used a NAT Gateway for package installation and required its removal, including release of the Elastic IP. A budget alert was created to monitor spending.

After collecting evidence, the lab cleaned up its EC2 instances and associated volumes, VPC resources, S3 backup bucket and objects, Lambda function, DynamoDB audit table, project IAM roles and policies, CloudWatch log group, and the project budget. Screenshots documenting cleanup are in [`screenshots/cleanup/`](../screenshots/cleanup/).

**Important:** budget alerts do not cap costs. Historical billing entries can remain after infrastructure deletion. This document does not assert any specific bill amount.
