# Secure AWS Backup & Audit Pipeline

**Private EC2 backups to Amazon S3, with event-driven audit records in DynamoDB.**

**Project status:** Completed Karatu 2026 cloud engineering assessment lab. AWS resources were deleted after verification and evidence collection. This repository documents the implementation; it is **not** a live deployment or a one-command infrastructure installer.

## The challenge

A company needs its private application server to back up data automatically, without assigning the server a public IP address or granting it permission to delete older backups. Every new S3 backup must also produce an audit record without manual intervention.

My solution combined private AWS networking, a tightly scoped EC2 IAM role, Linux automation, and an S3-triggered serverless audit function.

## Architecture

```mermaid
flowchart TD
    User["Administrator"] -->|SSH from allowed IP| Bastion

    subgraph VPC["AWS VPC · 10.0.0.0/16"]
        subgraph Public["Public subnet"]
            Bastion["Bastion EC2"]
        end
        subgraph Private["Private subnet"]
            App["Application EC2<br/>(No public IP)"]
        end
        Bastion -->|SSH restricted<br/>to bastion SG| App
        App -->|Upload with<br/>instance role| S3Endpoint["S3 Gateway Endpoint"]
    end

    S3Endpoint --> Bucket[("Private S3 bucket<br/>(backups/*)")]
    Bucket -->|ObjectCreated:Put<br/>(backups/)| Lambda["Lambda audit function"]
    Lambda -->|dynamodb:PutItem| Dynamo[("DynamoDB<br/>(backup-log)")]

    %% Styling
    classDef compute fill:#fef3c7,stroke:#f59e0b,stroke-width:2px,color:#78350f;
    classDef storage fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#14532d;
    classDef database fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a8a;
    classDef network fill:#f3e8ff,stroke:#9333ea,stroke-width:2px,color:#581c87;
    classDef user fill:#f1f5f9,stroke:#64748b,stroke-width:2px,color:#0f172a;

    class User user;
    class Bastion,App,Lambda compute;
    class Bucket storage;
    class Dynamo database;
    class S3Endpoint network;
```

The bastion is the SSH entry point. The application EC2 instance resides in the private subnet. The **S3 Gateway Endpoint** gives that instance a path to S3 after the temporary NAT Gateway is deleted. An S3 upload event invokes Lambda, which writes metadata to DynamoDB. **There is no EC2 Instance Connect Endpoint or DynamoDB Gateway Endpoint in this design.**

See the editable [architecture source](architecture/architecture.mmd) for the same topology.

## AWS services and responsibilities

| Component | Responsibility |
| --- | --- |
| VPC, subnets, routes, security groups | Isolate the app instance and restrict SSH access |
| Bastion EC2 | Provide controlled SSH access to the private instance |
| Private application EC2 | Generate logs and create backup archives |
| Temporary NAT Gateway | Support initial software installation; removed afterward |
| S3 Gateway Endpoint | Route private-subnet S3 traffic without permanent NAT |
| IAM instance role | Allow only `s3:PutObject` under the backup prefix |
| Amazon S3 | Store timestamped compressed backup archives |
| AWS Lambda | Process S3 PUT events automatically |
| Amazon DynamoDB | Record the object key, size, upload time, and bucket |
| CloudWatch Logs | Record Lambda invocations and diagnostic output |

## How the pipeline worked

1. A systemd service appended a timestamp to `/var/app/data/app.log` **every 30 seconds**, restarting if the process stopped.
2. Root's cron scheduled `backup.sh` **every 10 minutes**.
3. The Bash script archived `/var/app/data` as `backup-YYYY-MM-DD-HHMM.tar.gz`, uploaded it under `s3://<bucket>/backups/`, logged success or failure in `/var/log/backup.log`, and removed the local archive **only after a successful upload**.
4. S3 `ObjectCreated:Put` notifications on the `backups/` prefix invoked a Python Lambda function.
5. Lambda used `dynamodb:PutItem` to write `backup_id`, `size_bytes`, `uploaded_at`, and `bucket` to DynamoDB table `backup-log`.

## Security decisions

- **No public IP on the application server.** The bastion allowed SSH from the administrator's restricted IP, and the private instance accepted SSH only from the bastion's security group.
- **No stored AWS access keys on EC2.** The application used an instance IAM role.
- **Least-privilege S3 access.** The application's role granted `s3:PutObject` only on `backups/*`, not `s3:DeleteObject`. A deletion attempt returned `AccessDenied`.
- **No persistent NAT Gateway.** After setup, the NAT Gateway and its Elastic IP were removed; an S3 Gateway Endpoint continued to support backup uploads.
- **Separate audit permissions.** Lambda was permitted to write to the specific DynamoDB table and send execution logs to CloudWatch.

**Security boundary:** Preventing deletion through the EC2 role does *not* make S3 objects immutable against administrators or other principals. S3 Object Lock/versioning would be considered for a production environment.

## Verification and evidence

The assessment document contained screenshots documenting these results:

| Test | Observed result |
| --- | --- |
| SSH hop through bastion | Connected to the private instance |
| Data generator | Service `active (running)` and timestamped log entries |
| Backup schedule | `*/10 * * * * /usr/bin/bash /usr/local/bin/backup.sh` |
| S3 deletion attempt | `AccessDenied` for `s3:DeleteObject` |
| Backup uploads | Multiple `.tar.gz` backup objects visible in S3 |
| Audit trail | Multiple records in DynamoDB; screenshot showed 20 returned items |
| Lambda logs | CloudWatch showed a successful audit-record message |
| Internet isolation | `curl -m 5 https://example.com` timed out after NAT deletion |
| S3 without NAT | Subsequent backup upload succeeded |
| Cost cleanup | Project resources were removed after evidence collection |

Screenshot evidence is **not yet in the public folder**: it is being individually selected and redacted before release. See [validation notes](docs/VALIDATION.md). This repository does not claim to have rerun the original deployment.

## Repository contents

```text
architecture/    Mermaid diagram representing the assessment topology
scripts/         Backup script, cron schedule, reconstructed systemd service
lambda/          Reconstructed Python S3-event audit handler
iam/             Example resource-scoped IAM policies with placeholders
docs/            Setup context, verification, provenance, publication checks
screenshots/     Categorized evidence folders (pending redaction)
```

- [Backup script](scripts/backup.sh)
- [Observed cron schedule](scripts/crontab.txt)
- [Data generator service (reconstructed)](scripts/data-generator.service)
- [Lambda audit function (reconstructed)](lambda/lambda_function.py)
- [EC2 policy template](iam/ec2-backup-policy.json)
- [Lambda policy template](iam/lambda-dynamodb-policy.json)
- [Configuration and usage notes](docs/USAGE.md)
- [Source provenance and what was reconstructed](docs/SOURCE_PROVENANCE.md)

**About source files:** `backup.sh` was transcribed from editable assessment text, with its bucket name replaced by a required `BACKUP_BUCKET` environment variable for public sharing. The systemd unit, Lambda code and IAM policies were reconstructed from assessment requirements and screenshots, **not** exported as original deployed source. The optional cron wrapper and environment template are publication conveniences, not claims about the original deployment.

## Challenges and lessons learned

- Deleting the NAT Gateway left a **blackhole default route** in the private route table. The specific S3 Gateway Endpoint route continued to support uploads, which the `curl`-versus-backup test demonstrated.
- Least-privilege access needs functional proof: the successful upload and denied deletion established different sides of the permission boundary.
- A successful S3 upload and a successful audit entry are separate events. Checking DynamoDB alongside Lambda's CloudWatch logs helped verify the end-to-end pipeline.
- Cleanup matters in cloud labs: infrastructure and associated resources should be removed after collecting evidence to avoid avoidable ongoing charges.

## Production improvements to consider

This was an assessment implementation, not production-ready backup infrastructure. Future work would include S3 Versioning/Object Lock where appropriate, retention and lifecycle rules, alarms for failed or missing backups, tested restoration procedures, stronger backup integrity checks, and infrastructure as code. The current minute-resolution filenames also risk overwriting a backup if two runs occur within the same minute; the audit table's S3-key partition key can similarly overwrite a repeated-key record.

## Article

**Medium Link** (https://medium.com/@testyfresh/building-a-secure-and-automated-aws-backup-pipeline-with-ec2-s3-lambda-and-dynamodb-bd883e98103b)

## Reuse and limitations

See [usage notes](docs/USAGE.md) before adapting these examples. Replace all placeholders, inspect IAM policies, and verify regional networking and costs. The source code files are educational references and **do not** recreate the VPC, EC2, S3, DynamoDB, and Lambda resources by themselves. Never commit SSH private keys, AWS credentials, or screenshots containing sensitive account information.
