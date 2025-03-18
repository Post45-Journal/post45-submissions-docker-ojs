#!/bin/bash
set -e

: "${AZURE_FILE_SHARE_NAME:?Variable not set or empty}"
: "${AZURE_STORAGE_ACCOUNT_KEY:?Variable not set or empty}"
: "${AZURE_STORAGE_ACCOUNT_NAME:?Variable not set or empty}"
: "${MOUNT_POINT:?Variable not set or empty}"

# Print the current user (ensure this script is running as root)
echo "Running as user: $(whoami)"

# Create mount point if it doesn't exist
mkdir -p $MOUNT_POINT

# Mount Azure File Share using the storage account key
mount -t cifs //$AZURE_STORAGE_ACCOUNT_NAME.file.core.windows.net/$AZURE_FILE_SHARE_NAME $MOUNT_POINT -o vers=3.0,username=$AZURE_STORAGE_ACCOUNT_NAME,password=$AZURE_STORAGE_ACCOUNT_KEY,uid=apache,gid=www-data,dir_mode=0750,file_mode=0640,serverino

# Ensure the mount is successful
if mountpoint -q $MOUNT_POINT; then
  echo "Azure File Share mounted successfully at $MOUNT_POINT"
else
  echo "Failed to mount Azure File Share at $MOUNT_POINT"
  exit 1
fi

# Create required subdirectories if they don't exist
mkdir -p $MOUNT_POINT/files
mkdir -p $MOUNT_POINT/public

# Set permissions for the mounted directories
chown -R apache:www-data $MOUNT_POINT/files
find $MOUNT_POINT/files -type d -exec chmod 750 {} \;  # for directories
find $MOUNT_POINT/files -type f -exec chmod 640 {} \;  # for files

# Ensure that $MOUNT_POINT/public is accessible to the web server
chown -R apache:www-data $MOUNT_POINT/public
find $MOUNT_POINT/public -type d -exec chmod 750 {} \;  # for directories
find $MOUNT_POINT/public -type f -exec chmod 640 {} \;  # for files

echo "Permissions set for Azure File Share at $MOUNT_POINT"
