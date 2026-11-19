# Architecture (original project topology)

The source assessment required:

1. Administrator SSH to **bastion EC2 in public subnet**.
2. Bastion SSH to **private app EC2 without a public IP**.
3. Private EC2 uploads archives through the **S3 Gateway Endpoint**, without a permanent NAT Gateway.
4. New S3 PUT uploads under `backups/` trigger **Lambda**.
5. Lambda writes audit metadata to **DynamoDB `backup-log`**.

The Mermaid diagram in `architecture.mmd` is an original recreation of the deployed topology, not a claim that the original assessment image was authored by the repository owner.

The temporary NAT Gateway was used only to install software and deleted before NAT-less S3 testing. A DynamoDB Gateway Endpoint and EC2 Instance Connect Endpoint are **not** part of this project.
