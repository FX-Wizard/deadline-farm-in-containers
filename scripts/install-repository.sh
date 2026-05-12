#!/bin/sh
set -e

INSTALLER="/tmp/DeadlineRepository-10.4.2.3-linux-x64-installer.run"
REPO_DIR="/opt/Thinkbox/DeadlineRepository10"

# Check for a file that only exists after a successful install
if [ -f "$REPO_DIR/settings/connection.ini" ]; then
  echo "Deadline Repository already installed at $REPO_DIR, skipping installation."
else
  echo "Installing Deadline Repository..."

  "$INSTALLER" \
    --mode unattended \
    --installmongodb false \
    --dbhost deadline_db \
    --dbport 27017 \
    --dbssl false \
    --dbauth false \
    --prefix "$REPO_DIR" \
    --setpermissions true

  echo "Repository installation complete."
fi

# Hand off to CMD (keeps container running)
exec "$@"
