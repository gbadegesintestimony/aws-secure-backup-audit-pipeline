# Phase 1: Source inventory

Source: the private 11-page assessment submission (11 pages), cross-checked against the official Karatu project-assessment PDF.

## Extracted with high confidence

| File | Evidence and status |
|---|---|
| `scripts/backup.sh` | Transcribed directly from **editable text** in the assessment document, page 3. Original script contained a project-specific bucket name. The published script uses a placeholder environment variable. |
| `scripts/crontab.txt` | Transcribed from the root crontab **screenshot** in document page 4; command `*/10 * * * * /usr/bin/bash /usr/local/bin/backup.sh`. |
| `architecture/architecture.mmd` | Original Mermaid recreation of the official assessment architecture, preserving all required services and connections; the assessment artwork itself is not redistributed. |

## Visually evidenced, but source files not provided as editable code

- `data-generator.service` and app.log: systemd state and timestamps visible in page 2 screenshots; exact original unit-file contents **not included as editable text**.
- `lambda_function.py`: Lambda configuration and CloudWatch results are shown on page 6, but exact deployable function source was **not provided as editable text**.
- `ec2-backup-policy.json`: upload-only policy appears in IAM screenshots, but editable JSON is not present in the document.
- `lambda-dynamodb-policy.json`: screenshot shows `dynamodb:PutItem` for `backup-log`; the original policy file is not provided.
- Screenshots: 29 embedded PNG images were found in the source DOCX, including network/SSH evidence, IAM configuration, backup logs, S3 objects, DynamoDB, Lambda, and cleanup. Screenshots are **curated and masked** for this combined portfolio package; review the resulting images before publishing.
- Medium article URL: not included in the uploaded assessment document.

## Evidence-to-page mapping

| Category | Document pages | Notes |
|---|---|---|
| Network and security groups | 1–2 | VPC map, routes, security groups, SSH hop |
| Data generator | 2 | Running systemd service and application timestamps |
| Backup script | 3 | Exact Bash text |
| Cron and IAM | 4 | Cron schedule, role/policy, denied delete |
| S3 backup evidence | 5 | Multiple backup objects and success log |
| DynamoDB and Lambda | 6 | Matching audit entries, S3 trigger and role policy |
| NAT-less S3 test and budget | 7 | Failed external curl and successful S3 upload |
| Cleanup evidence | 8–11 | IAM, Lambda, CloudWatch, budget, EC2, S3, VPC, DynamoDB |

## Limits of the evidence

Screenshot evidence supports completion of the assignment, but does not demonstrate that code can currently be redeployed from this package. Resources were cleaned up. No claims of Terraform, CI/CD, disaster-recovery validation, Object Lock, or production readiness are supported by these sources.
