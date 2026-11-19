# Source provenance

**Assessment sources:** private 11-page DOCX with embedded implementation screenshots and the official six-page project PDF. These original documents are not included in this shareable GitHub repo.

**Directly source-backed:** `scripts/backup.sh` was transcribed from assessment editable text, with the original literal bucket name replaced by the `BACKUP_BUCKET` environment variable. The historical root cron line matches the screenshot. Screenshot evidence has been extracted, categorized and masked.

**Reconstructed examples (not source exports):** `scripts/data-generator.service`, `lambda/lambda_function.py`, and `iam/*.json` are reconstructed from the assessment requirements, pictured role permissions, and Lambda evidence. `scripts/backup-cron-wrapper.sh` and `scripts/karatu-backup.env.example` are optional portfolio examples.

**Architecture:** `architecture/architecture.mmd` is an original representation of the required topology. It is **not** a claim of authorship of the supplied assessment drawing.

**Not claimed:** Live infrastructure, automated provisioner, production immutable backups, retention controls, restore drills, CI/CD, Terraform, or performance testing.
