# Lessons learned and future improvements

This project connects networking, identity, scheduled Linux jobs, S3 storage and event-driven serverless processing. The most valuable proof is not merely creating resources but demonstrating both allowed and forbidden behavior: S3 uploads work from a private host, delete calls fail, and audit rows appear automatically.

For production: consider S3 Versioning/Object Lock, encryption/key management, expiry and lifecycle policies, failure alerts, restoration and integrity checks, high availability and infrastructure-as-code. The lab does not claim any of those were implemented.

**Known limitations:** minute-resolution backup filenames can collide; `backup_id` based only on the S3 key can overwrite an existing audit item for duplicate/repeated events. An EC2 role without delete permission is not equivalent to account-wide immutability.
