#!/bin/bash

# Check if the backup directory exists
BACKUP_DIR="/usr/share/soltros/settings/soltros-look_cosmic/"
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "Error: Backup directory not found at ${BACKUP_DIR}"
    exit 1
fi

echo "Restoring Cosmic settings from: ${BACKUP_DIR}"

# --- Copy Configuration Files ---
cp -a "${BACKUP_DIR}/." "${HOME}/.config/cosmic/"

