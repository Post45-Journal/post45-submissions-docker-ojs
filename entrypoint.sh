#!/bin/bash
set -e

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# Mount Azure File Share
/usr/local/bin/mount-azure-file-share.sh

echo "Starting SSH ..."
/usr/sbin/sshd

chmod +x /usr/local/bin/ojs-variable
# Temporary fix for error in ojs-variable (fixed here https://gitlab.com/pkp-org/docker/ojs/-/commit/f4f33f370e7c765b599868f0ca701898c875b47f, but not in stable-3_4_0 branch)
sed -i 's:/tmp/ojs.config.inc.php:/tmp/config.inc.php:' /usr/local/bin/ojs-variable

echo "Adding symlink to persistent /mnt/azure/public directory in web root"
ln -s /mnt/azure/public /var/www/html/public || echo "Symlink already exists"

declare -A configVariable
if [ -f $SAVED_OJS_CONF ]
then 
  echo "Using existing config.inc.php from /mnt/azure/files/config.inc.php"
  cp $SAVED_OJS_CONF $OJS_CONF 
else
  # Set config variables using env variables https://github.com/pkp/ojs/blob/main/config.TEMPLATE.inc.php
  echo "No existing config in /mnt/azure/files. Updating OJS config based on env variables..."
  # General
  configVariable["installed"]="On"
  # configVariable["base_url"]=$WEBSITE_HOSTNAME
  configVariable["base_url"]="https://submissions.post45.org"
  configVariable["time_zone"]=$TIME_ZONE
  configVariable["restful_urls"]="On"
  # Database
  configVariable["host"]=$OJS_DB_HOST
  configVariable["username"]=$OJS_DB_USER
  configVariable["password"]=$OJS_DB_PASSWORD
  configVariable["name"]=$OJS_DB_NAME
  # Locatlization
  configVariable["locale"]="en"
  # Files
  configVariable["files_dir"]="/mnt/azure/files"
  configVariable["public_files_dir"]="/mnt/azure/public"
  # Security
  configVariable["force_ssl"]="On"
  configVariable["salt"]=$SALT
  configVariable["api_key_secret"]=$API_KEY_SECRET
  # Email
  configVariable["smtp_server"]="smtp-relay.gmail.com"
  configVariable["smtp_port"]="587"
  configVariable["smtp_auth"]="tls"
  configVariable["smtp_username"]=$SMTP_USERNAME
  configVariable["smtp_password"]=$SMTP_PASSWORD
  configVariable["allow_envelope_sender"]="On"
  configVariable["default_envelope_sender"]="no-reply@post45.org"
  # OAI
  configVariable["oai"]="Off"
  for key in "${!configVariable[@]}"; do
    ojs-variable $key ${configVariable[$key]}
  done
  cp $OJS_CONF $SAVED_OJS_CONF
fi

chmod +x /usr/local/bin/ojs-start
ojs-start