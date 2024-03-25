#!/bin/bash

# Perform setup
set -x # Starts debugging mode 
DEV_NAME="$(lsblk --output NAME --list | tail -n 1)" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
DEV_FS_TYPE="ext4" # Specifies the file system type to be used for formatting the EBS volume.
MOUNT_POINT="/data" # Sets the mount point directory for the EBS volume.
set +x 

# Format EBS volume, if not already formatted
sudo file -s "/dev/$DEV_NAME" | grep "$DEV_FS_TYPE"

# If a file system is present, it skips formatting. Otherwise, it formats the device using mkfs.
if [ $? -eq 0 ]; then
  echo "File system already exists on /dev/$DEV_NAME, not going to format"
else
  echo "No file system on /dev/$DEV_NAME, formatting"
  sudo mkfs -t "$DEV_FS_TYPE" "/dev/$DEV_NAME"
fi

# Enters a loop to wait until the UUID of the EBS device is determined.
while true; do
  uuid="$(ls -la /dev/disk/by-uuid/ | grep $DEV_NAME | sed -e 's/.*\([0-9a-f-]\{36\}\).*/\1/')" 
  if [ ! -z "$uuid" ]; then
    echo "EBS device \"$uuid\" found"
    break
  fi
  echo "Waiting for EBS device..."
  sleep 1
done

# Mount EBS volume, and set it to auto-mount after reboots
sudo mkdir "$MOUNT_POINT" # Creates the mount point directory if it doesn't exist already.
echo "UUID=$uuid  $MOUNT_POINT  $DEV_FS_TYPE  defaults,nofail  0  2" | sudo tee -a /etc/fstab # Appends an entry to /etc/fstab for auto-mounting the EBS volume on system reboots.
sudo mount -a # Mounts the EBS volume immediately.

# List the filesystems, for debugging convenience
df -h