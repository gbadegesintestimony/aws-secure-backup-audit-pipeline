#!/bin/bash
# PUBLIC PORTFOLIO TEMPLATE, not a file proven deployed in the assessment.
set -euo pipefail
set -a
source /etc/karatu-backup.env
set +a
exec /usr/bin/bash /usr/local/bin/backup.sh
