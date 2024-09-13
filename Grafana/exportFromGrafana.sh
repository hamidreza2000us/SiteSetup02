#!/bin/bash

# File: db-export.sh

### --- Default settings ---
HOST="${HOST:-http://localhost:3000}"
DEFAULT_USER="admin"
DEFAULT_PASSWORD="ahoora"
###

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check and create directories if they do not exist
if [ ! -d $SCRIPT_DIR/dashboards ] ; then
    mkdir -p $SCRIPT_DIR/dashboards
fi
if [ ! -d $SCRIPT_DIR/folders ] ; then
    mkdir -p $SCRIPT_DIR/folders
fi

# Ask user for confirmation to use default or change credentials
read -p "Enter Grafana host (default: ${HOST}): " input_host
HOST=${input_host:-$HOST}

read -p "Enter Grafana username (default: ${DEFAULT_USER}): " input_user
USER=${input_user:-$DEFAULT_USER}

read -sp "Enter Grafana password (default: hidden): " input_pass
PASSWORD=${input_pass:-$DEFAULT_PASSWORD}
echo ""

# Export dashboards
for dash in $(curl -s -k -u $USER:$PASSWORD "$HOST/api/search?query=&" | jq -r '.[] | select(.type == "dash-db") | .uid'); do
  title=$(curl -s -k -u $USER:$PASSWORD "$HOST/api/dashboards/uid/$dash" | jq -r '.dashboard.title' | sed 's/ /-/g')

  # Save dashboard JSON
  curl -s -k -u $USER:$PASSWORD "$HOST/api/dashboards/uid/$dash" \
    | jq '. |= (.folderUid=.meta.folderUid) |del(.meta) |del(.dashboard.id) + {overwrite: true}' \
    > dashboards/${title}.json

  echo "Dashboard: ${title} saved."
done

# Export folders
for folder in $(curl -s -k -u $USER:$PASSWORD "$HOST/api/folders" | jq -r '.[] | .uid'); do
  title=$(curl -s -k -u $USER:$PASSWORD "$HOST/api/folders/$folder" | jq -r '.title' | sed 's/ /-/g')

  # Save folder JSON
  curl -s -k -u $USER:$PASSWORD "$HOST/api/folders/$folder" \
    | jq '. |del(.id) + {overwrite: true}' \
    > folders/${title}.json

  echo "Folder: ${title} saved."
done
