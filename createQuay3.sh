#!/bin/bash

# Initial settings
OCP_RELEASE="4.16.4"  # OpenShift version
LOCAL_REGISTRY="172.18.109.61:8443"  # Local registry hostname and port
LOCAL_REPOSITORY="ocp4/openshift4"  # Local repository path to store images
PRODUCT_REPO="openshift-release-dev"
RELEASE_NAME="ocp-release"
LOCAL_SECRET_JSON='../pullsecret'  # Path to pull secret file
BASE_DIR="/opt/quay"  # Base directory for Quay setup
REGISTRY_DATA_DIR="$BASE_DIR/datastorage"  # Directory to store registry data
SYSTEM_CERT_DIR="$BASE_DIR/certs"  # Directory to store system certificates
CONFIG_DIR="$BASE_DIR/conf/stack"  # Directory to store Quay config files
COMPOSE_FILE="$BASE_DIR/podman-compose.yml"

# Ensure the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Creating base directory at $BASE_DIR..."
    sudo mkdir -p $BASE_DIR
fi

# Ensure the registry data directory exists
if [ ! -d "$REGISTRY_DATA_DIR" ];then
    echo "Creating registry data directory at $REGISTRY_DATA_DIR..."
    sudo mkdir -p $REGISTRY_DATA_DIR
fi

# Ensure the system certificate directory exists
if [ ! -d "$SYSTEM_CERT_DIR" ];then
    echo "Creating system certificate directory at $SYSTEM_CERT_DIR..."
    sudo mkdir -p $SYSTEM_CERT_DIR
fi

# Ensure the Quay config directory exists
if [ ! -d "$CONFIG_DIR" ];then
    echo "Creating Quay config directory at $CONFIG_DIR..."
    sudo mkdir -p $CONFIG_DIR
fi

# Set the correct permissions and SELinux context for the directories
echo "Setting permissions and SELinux context for the directories..."
sudo chown -R $(id -u):$(id -g) $BASE_DIR
sudo chmod -R 755 $BASE_DIR
sudo chcon -R system_u:object_r:container_file_t:s0 $BASE_DIR

# Generate SSL certificates with SANs if they do not exist
SSL_CERT="$SYSTEM_CERT_DIR/ssl.cert"
SSL_KEY="$SYSTEM_CERT_DIR/ssl.key"

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ];then
    echo "Generating SSL certificates with SANs..."
    sudo openssl req -newkey rsa:4096 -nodes -keyout $SSL_KEY -x509 -days 365 -out $SSL_CERT -subj "/CN=quay.local" \
    -addext "subjectAltName = DNS:quay.local,IP:172.18.109.61"
    sudo chmod 644 $SSL_CERT $SSL_KEY  # Set appropriate permissions for the SSL files
fi

# Add the self-signed certificate to the system's trusted CA store
echo "Adding the self-signed certificate to the system's trusted CA store..."
sudo cp $SSL_CERT /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Create init.sql for installing pg_trgm extension
echo "Creating init.sql for PostgreSQL..."
sudo bash -c "cat <<EOF > $BASE_DIR/init.sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOF"

# Create config.yaml for Quay with PostgreSQL and local storage configuration
echo "Creating config.yaml for Quay..."
sudo bash -c "cat <<EOF > $CONFIG_DIR/config.yaml
FEATURE_MAILING: false
DB_URI: postgresql://quayuser:quaypassword@postgres:5432/quaydb
DATABASE_SECRET_KEY: 788355d3-0bd4-400e-8f13-9423b0557db3
SERVER_HOSTNAME: 172.18.109.61:8443
PREFERRED_URL_SCHEME: https
BUILDLOGS_REDIS:
  host: redis
  port: 6379
USER_EVENTS_REDIS:
    host: redis
    port: 6379
DISTRIBUTED_STORAGE_CONFIG:
  local_us:
    - LocalStorage
    - storage_path: /datastorage/registry
EXTERNAL_TLS_TERMINATION: false

FEATURE_ACI_CONVERSION: false
FEATURE_ACTION_LOG_ROTATION: false
FEATURE_ANONYMOUS_ACCESS: true
FEATURE_APP_REGISTRY: false
FEATURE_APP_SPECIFIC_TOKENS: true
FEATURE_BITBUCKET_BUILD: false
FEATURE_BLACKLISTED_EMAILS: false
FEATURE_BUILD_SUPPORT: false
FEATURE_CHANGE_TAG_EXPIRATION: true
FEATURE_DIRECT_LOGIN: true
FEATURE_EXTENDED_REPOSITORY_NAMES: true
FEATURE_FIPS: false
FEATURE_GITHUB_BUILD: false
FEATURE_GITHUB_LOGIN: false
FEATURE_GITLAB_BUILD: false
FEATURE_GOOGLE_LOGIN: false
FEATURE_INVITE_ONLY_USER_CREATION: false
FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP: false
FEATURE_PARTIAL_USER_AUTOCOMPLETE: true
FEATURE_PROXY_STORAGE: false
FEATURE_REPO_MIRROR: false
FEATURE_REQUIRE_TEAM_INVITE: true
FEATURE_RESTRICTED_V1_PUSH: true
FEATURE_SECURITY_NOTIFICATIONS: false
FEATURE_SECURITY_SCANNER: false
FEATURE_STORAGE_REPLICATION: false
FEATURE_TEAM_SYNCING: false
FEATURE_USER_CREATION: true
FEATURE_USER_LAST_ACCESSED: true
FEATURE_USER_LOG_ACCESS: false
FEATURE_USER_METADATA: false
FEATURE_USER_RENAME: false
FEATURE_USERNAME_CONFIRMATION: true
FRESH_LOGIN_TIMEOUT: 10m
GITHUB_LOGIN_CONFIG: {}
GITHUB_TRIGGER_CONFIG: {}
GITLAB_TRIGGER_KIND: {}
LDAP_ALLOW_INSECURE_FALLBACK: false
LDAP_EMAIL_ATTR: mail
LDAP_UID_ATTR: uid
LDAP_URI: ldap://localhost
LOG_ARCHIVE_LOCATION: default
LOGS_MODEL: database
LOGS_MODEL_CONFIG: {}
REGISTRY_TITLE: Project Quay
REGISTRY_TITLE_SHORT: Project Quay
REPO_MIRROR_INTERVAL: 30
REPO_MIRROR_TLS_VERIFY: true
SEARCH_MAX_RESULT_PAGE_COUNT: 10
SEARCH_RESULTS_PER_PAGE: 10
SECRET_KEY: 4eec4dff-062a-42e8-9890-c5fa9bb951b8
SECURITY_SCANNER_INDEXING_INTERVAL: 30
SETUP_COMPLETE: true
SUPER_USERS:
    - admin
EOF"

# Create podman-compose.yml for Quay and PostgreSQL
echo "Creating $COMPOSE_FILE for Quay setup..."
sudo bash -c "cat <<EOF > $COMPOSE_FILE
version: '3'
services:
  postgres:
    image: postgres:13
    container_name: quay-postgres
    restart: always
    environment:
      POSTGRES_DB: quaydb
      POSTGRES_USER: quayuser
      POSTGRES_PASSWORD: quaypassword
    volumes:
      - $BASE_DIR/postgres_data:/var/lib/postgresql/data
      - $BASE_DIR/init.sql:/docker-entrypoint-initdb.d/init.sql:ro

  quay:
    image: quay.io/projectquay/quay:latest
    container_name: quay
    restart: always
    environment:
      - QUAY_SETUP_TABLE=1
      - DATABASE_SECRET_KEY=mysecretkey
      - SECRET_KEY=mysecretkey
    depends_on:
      - postgres
    ports:
      - "8443:8443"
    volumes:
      - $CONFIG_DIR:/conf/stack
      - $REGISTRY_DATA_DIR:/datastorage
      - $SYSTEM_CERT_DIR/ssl.cert:/conf/stack/ssl.cert:ro
      - $SYSTEM_CERT_DIR/ssl.key:/conf/stack/ssl.key:ro

  redis:
    image: redis:alpine
    container_name: quay-redis
    restart: always
    volumes:
      - $BASE_DIR/redis_data:/data

EOF"

# Start Quay and PostgreSQL with podman-compose
echo "Starting Quay and PostgreSQL with podman-compose..."
sudo podman-compose -f $COMPOSE_FILE up -d

echo "Quay and PostgreSQL services have been started successfully."
#create user ocp4
#set password
#make repo public for oc access
#login to create auth file
#pass authfile to oc 
