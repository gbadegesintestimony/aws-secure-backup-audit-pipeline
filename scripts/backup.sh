#!/bin/bash
set -euo pipefail
# Stage 3: Karatu automated backup script
# Make required commands available under cron
export PATH=/usr/local/bin:/usr/bin:/bin
# Configuration
BUCKET="${BACKUP_BUCKET:?Set BACKUP_BUCKET to your S3 bucket name}"
SOURCE_DIR="/var/app/data"
LOG_FILE="/var/log/backup.log"
ARCHIVE_DIR="/var/tmp"
# Timestamp and archive name
TIMESTAMP=$(/usr/bin/date +%Y-%m-%d-%H%M)
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"
S3_DESTINATION="s3://${BUCKET}/backups/${ARCHIVE_NAME}"
# Write a timestamped entry to the backup log
log_message() {
echo "$(/usr/bin/date -Is) - $1" >> "$LOG_FILE"
}
# Record any failure that prevents completion
on_exit() {
STATUS=$?
if [ "$STATUS" -ne 0 ]; then
log_message "FAILURE: ${ARCHIVE_NAME} (exit status ${STATUS})"
fi
}
trap on_exit EXIT
log_message "START: ${ARCHIVE_NAME}"
# Create a compressed archive of /var/app/data
/usr/bin/tar -czf "$ARCHIVE_PATH" -C /var/app data
# Upload the archive to Amazon S3
aws s3 cp "$ARCHIVE_PATH" "$S3_DESTINATION"
# Delete the local archive only after successful upload
/usr/bin/rm -f "$ARCHIVE_PATH"
log_message "SUCCESS: ${ARCHIVE_NAME} uploaded to ${S3_DESTINATION}"
