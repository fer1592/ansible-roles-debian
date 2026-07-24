#!/bin/bash
set -eEuf -o pipefail

BACKUP_MOUNT="/mnt/backup"
BACKUP_FOLDERS=(
    "/home/$(whoami)/Code"
    "/home/$(whoami)/ansible-roles-debian-data"
)
BACKUP_DATE=$(date +"%d-%m-%Y")
BACKUP_FILE="debian-server-backup-${BACKUP_DATE}.tar.gz"
BACKUP_TEMP_DIR="/home/$(whoami)/backup"
BACKUP_EXTERNAL_DEVICE="/dev/sda1"

mkdir -p "$BACKUP_TEMP_DIR"
mkdir -p "$BACKUP_MOUNT"

echo "=== Starting backup - $(date) ==="
if [[ ${#BACKUP_FOLDERS[@]} -eq 0 ]]; then
    echo "Error: No folders defined in the FOLDERS array"
    exit 1
fi

echo "Folders to backup: ${#BACKUP_FOLDERS[@]}"

if [[ -f "$BACKUP_TEMP_DIR/$BACKUP_FILE" ]]; then
    echo "Compressed backup already exists at $BACKUP_TEMP_DIR/$BACKUP_FILE. Skipping!"
else
    echo "Creating compressed backup: $BACKUP_TEMP_DIR/$BACKUP_FILE"
    sudo tar -czf "$BACKUP_TEMP_DIR/$BACKUP_FILE" \
        --exclude-backups \
        --exclude-caches \
        "${BACKUP_FOLDERS[@]}" 2>/tmp/backup-errors.log
    echo "Backup created successfully."
fi

echo "Mounting external drive ($BACKUP_EXTERNAL_DEVICE)..."

if mountpoint -q "$BACKUP_MOUNT"; then
    echo "Already mounted."
else
    sudo mount "$BACKUP_EXTERNAL_DEVICE" "$BACKUP_MOUNT"
fi

echo "Copying backup to external drive..."
cp "$BACKUP_TEMP_DIR/$BACKUP_FILE" "$BACKUP_MOUNT/"
echo "Success! Backup saved as: $BACKUP_MOUNT/$BACKUP_FILE"

echo "Unmounting..."
sudo umount "$BACKUP_MOUNT"

rm -rf "$BACKUP_TEMP_DIR"

echo "=== Backup finished - $(date) ==="
echo -e "\a"
