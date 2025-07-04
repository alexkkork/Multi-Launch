#!/bin/bash

# MultiLaunch Installation Script (Final Version)
# This script downloads MultiLaunch from its official GitHub releases,
# cleans up any prior installations (both proper bundles and lingering files),
# handles macOS security attributes, moves it to /Applications,
# and attempts to launch it.

DOWNLOAD_URL="https://github.com/alexkkork/Multi-Launch/releases/download/Launch/MultiLaunch.zip"
TEMP_ZIP_FILE="/tmp/MultiLaunch_download_$(date +%s).zip"
TEMP_EXTRACT_DIR="/tmp/MultiLaunch_extract_$(date +%s)"
TARGET_APP_NAME="MultiLaunch.app"
TARGET_APPLICATIONS_DIR="/Applications"
USER_APPLICATIONS_DIR="$HOME/Applications"
FINAL_APP_PATH="${TARGET_APPLICATIONS_DIR}/${TARGET_APP_NAME}"
USER_APP_PATH="${USER_APPLICATIONS_DIR}/${TARGET_APP_NAME}"

echo "🚀 Initiating MultiLaunch installation (from ZIP, with cleanup and launch)..."

# Step 1: Clean up any existing variations
echo "Searching for and removing previous MultiLaunch installations..."
# Remove from /Applications (handles both directory bundles and lingering files)
if [ -d "$FINAL_APP_PATH" ]; then
    echo "  Found existing MultiLaunch in /Applications. Removing..."
    sudo rm -rf "$FINAL_APP_PATH" || { echo "❌ Error: Failed to remove existing app in /Applications. Sudo permissions required."; exit 1; }
elif [ -f "$FINAL_APP_PATH" ]; then
    echo "  Found lingering MultiLaunch file in /Applications. Removing..."
    sudo rm -f "$FINAL_APP_PATH" || { echo "❌ Error: Failed to remove lingering file in /Applications. Sudo permissions required."; exit 1; }
fi

# Remove from ~/Applications (handles both directory bundles and lingering files)
if [ -d "$USER_APP_PATH" ]; then
    echo "  Found existing MultiLaunch in ~/Applications. Removing..."
    rm -rf "$USER_APP_PATH" || { echo "❌ Error: Failed to remove existing app in ~/Applications."; exit 1; }
elif [ -f "$USER_APP_PATH" ]; then
    echo "  Found lingering MultiLaunch file in ~/Applications. Removing..."
    rm -f "$USER_APP_PATH" || { echo "❌ Error: Failed to remove lingering file in ~/Applications."; exit 1; }
fi

# Remove any other potential residual temporary files from previous attempts
rm -f /tmp/MultiLaunch_download_*.zip
rm -rf /tmp/MultiLaunch_extract_*
rm -f /tmp/MultiLaunch_binary_* # Clean up old binary download attempts
rm -rf /tmp/MultiLaunch_temp_app_* # Clean up old app bundle creation attempts

# Step 2: Download the MultiLaunch ZIP file
echo "Downloading MultiLaunch ZIP package..."
if ! curl -L -o "$TEMP_ZIP_FILE" "$DOWNLOAD_URL"; then
    echo "❌ Error: Failed to download MultiLaunch ZIP. Exiting."
    exit 1
fi

# Step 3: Create temporary directory and unzip
echo "Extracting application files from ZIP..."
if ! mkdir -p "$TEMP_EXTRACT_DIR"; then
    echo "❌ Error: Failed to create temporary extraction directory. Exiting."
    rm -f "$TEMP_ZIP_FILE"
    exit 1
fi

# Unzip the contents (quietly) to the temporary extraction directory
if ! unzip -q "$TEMP_ZIP_FILE" -d "$TEMP_EXTRACT_DIR"; then
    echo "❌ Error: Failed to unzip MultiLaunch package. Exiting."
    rm -f "$TEMP_ZIP_FILE"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi
rm -f "$TEMP_ZIP_FILE" # Clean up the downloaded ZIP file immediately

# Step 4: Find the .app bundle inside the extracted contents (it might be nested in a folder)
UNZIPPED_APP_PATH=$(find "$TEMP_EXTRACT_DIR" -type d -name "*.app" -maxdepth 2 -print -quit)

if [ -z "$UNZIPPED_APP_PATH" ]; then
    echo "❌ Error: MultiLaunch.app not found in the extracted package. Exiting."
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi

# Step 5: Remove quarantine attribute and set executable permissions
echo "Configuring permissions and preparing MultiLaunch for use..."
# Remove macOS quarantine attribute (suppress output)
if ! xattr -rd com.apple.quarantine "$UNZIPPED_APP_PATH" &>/dev/null; then
    echo "⚠️ Warning: Could not remove quarantine attributes. You might need to manually approve the app."
fi
# Set executable permissions recursively (suppress output)
if ! chmod -R +x "$UNZIPPED_APP_PATH" &>/dev/null; then
    echo "⚠️ Warning: Could not set executable permissions for MultiLaunch."
fi

# Step 6: Move to /Applications
echo "Moving MultiLaunch to the /Applications folder..."
# Ensure /Applications exists (it almost always does on macOS)
sudo mkdir -p "$TARGET_APPLICATIONS_DIR" &>/dev/null

# Move the unzipped app bundle to the final /Applications path
if ! sudo mv "$UNZIPPED_APP_PATH" "$FINAL_APP_PATH"; then
    echo "❌ Error: Failed to move MultiLaunch to /Applications. This usually requires your password."
    echo "Please ensure you have administrator privileges and try again."
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi

# Step 7: Clean up temporary directory
rm -rf "$TEMP_EXTRACT_DIR"

echo "✅ MultiLaunch installation complete!"
echo "You can now find MultiLaunch in your Applications folder."

# Step 8: Launch the application
echo "Launching MultiLaunch..."
if open "$FINAL_APP_PATH"; then
    echo "MultiLaunch launched successfully."
else
    echo "❌ Error: Failed to launch MultiLaunch. You may need to launch it manually."
fi
