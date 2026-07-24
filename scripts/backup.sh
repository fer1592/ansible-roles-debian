#!/bin/bash
set -eEuf -o pipefail

BACKUP_MOUNT="/mnt/backup"
BACKUP_FOLDERS=(
    "~/Code"
    "~/ansible-roles-debian-data"
)
BACKUP_DATE=$(date +"%d-%m-%Y")
BACKUP_FILE="debian-server-backup-${BACKUP_DATE}.tar.gz"
BACKUP_TEMP_DIR="/tmp/backup"
mkdir -p "$BACKUP_TEMP_DIR"

echo "=== Starting backup - $(date) ==="
if [ ${#FOLDERS[@]} -eq 0 ]; then
    echo "Error: No folders defined in the FOLDERS array"
    exit 1
fi

echo "Folders to backup: ${#FOLDERS[@]}"

echo "Creating compressed backup: $BACKUP_TEMP_DIR/$BACKUP_FILE"
sudo tar -czf "$BACKUP_TEMP_DIR/$BACKUP_FILE" \
    --exclude-backups \
    --exclude-caches \
    "${FOLDERS[@]}" 2>/tmp/backup-errors.log
echo "Backup created successfully."

echo "Mounting external drive ($EXTERNAL_DEVICE)..."
if mountpoint -q "$BACKUP_MOUNT"; then
    echo "Already mounted."
else
    sudo mount "$EXTERNAL_DEVICE" "$BACKUP_MOUNT"
fi

echo "Copying backup to external drive..."
cp "$BACKUP_TEMP_DIR/$BACKUP_FILE" "$BACKUP_MOUNT/"
echo "Success! Backup saved as: $BACKUP_MOUNT/$BACKUP_FILE"

echo "Unmounting..."
sudo umount "$BACKUP_MOUNT"

echo "=== Backup finished - $(date) ==="
echo -e "\a"
