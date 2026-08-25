#!/bin/bash

set -euo pipefail

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display an error message and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display an informational message
info_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Function to display a warning message
warn_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Step 1: Display the download link for Android Studio
ANDROID_STUDIO_URL="https://developer.android.com/studio"
info_msg "Download Android Studio from this link: $ANDROID_STUDIO_URL"
read -r -p "Press Enter once the download is complete. " _

# Step 2: Check for the presence of the .tar.gz file in ~/Downloads
DOWNLOAD_DIR="$HOME/Downloads"
TAR_FILE=$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f -name "*android-studio*.tar.gz" 2>/dev/null | head -n 1)

if [ -n "$TAR_FILE" ]; then
    info_msg "File found: $TAR_FILE"
    read -r -p "Do you confirm this is the correct file? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        TAR_FILE=""
    fi
fi

# Step 3: Manually request the path if no file is found
while [ -z "$TAR_FILE" ] || [ ! -f "$TAR_FILE" ]; do
    read -r -p "Enter the full path to the Android Studio .tar.gz file: " TAR_FILE
    if [ ! -f "$TAR_FILE" ]; then
        warn_msg "File '$TAR_FILE' does not exist. Try again."
    fi
done

info_msg "Confirmed file: $TAR_FILE"

# Step 4: Extract the file to ~/.local/share/android-studio
INSTALL_DIR="$HOME/.local/share/android-studio"
info_msg "Extracting $TAR_FILE to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
if ! tar -xzf "$TAR_FILE" -C "$INSTALL_DIR" --strip-components=1; then
    error_exit "Failed to extract file $TAR_FILE."
fi

# Step 5: Install KVM dependencies in parallel
info_msg "Installing KVM dependencies in the background..."
sudo apt-get update -qq
sudo apt-get install -y -qq qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils > /dev/null 2>&1 &
KVM_PID=$!

# Step 6: Verify and start Android Studio
STUDIO_SCRIPT="$INSTALL_DIR/bin/studio"
if [ -f "$STUDIO_SCRIPT" ]; then
    chmod +x "$STUDIO_SCRIPT"
    info_msg "Starting Android Studio installation..."
    exec "$STUDIO_SCRIPT"
else
    error_exit "Script $STUDIO_SCRIPT does not exist. Check the path or the archive content."
fi

# Wait for KVM dependencies installation to complete
wait $KVM_PID
info_msg "KVM dependencies installation complete."
