#!/bin/sh
BACKUP_DIR="/backups"

DATE=$(date +"%Y-%m-%d_%H-%M")
FILE="$BACKUP_DIR/paperless_$DATE.dump"

mkdir -p "$BACKUP_DIR"

# Because PGHOST, PGUSER, PGPASSWORD are defined as env variables,
# pddump know them already:
pg_dump -Fc "${PGDATABASE}" > "$FILE"

# Delete backups older than 14 days
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +14 -delete