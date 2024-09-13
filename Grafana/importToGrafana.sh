#!/bin/bash

# File: db-import.sh

### --- Default settings ---
HOST="${HOST:-http://localhost:3000}"
DEFAULT_USER="admin"
DEFAULT_PASSWORD="ahoora"
###

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask user for confirmation to use default or change credentials
read -p "Enter Grafana host (default: ${HOST}): " input_host
HOST=${input_host:-$HOST}

read -p "Enter Grafana username (default: ${DEFAULT_USER}): " input_user
USER=${input_user:-$DEFAULT_USER}

read -sp "Enter Grafana password (default: hidden): " input_pass
PASSWORD=${input_pass:-$DEFAULT_PASSWORD}
echo ""

# Import folders
for folder in $SCRIPT_DIR/folders/*.json; do
  curl -s -X POST \
    -u $USER:$PASSWORD \
    -H 'Content-Type: application/json' \
    --data-binary @${folder} \
    ${HOST}/api/folders
  echo "Folder ${folder} imported."
done

# Import dashboards
for dash in $SCRIPT_DIR/dashboards/*.json; do
  curl -s -X POST \
    -u $USER:$PASSWORD \
    -H 'Content-Type: application/json' \
    --data-binary @${dash} \
    ${HOST}/api/dashboards/db
  echo "Dashboard ${dash} imported."
done
