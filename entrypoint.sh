#!/bin/bash
set -e

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)
 
echo "Starting SSH ..."
/usr/sbin/sshd

chmod +x /usr/local/bin/ojs-variable
# Temporary fix for error in ojs-variable (fixed here https://gitlab.com/pkp-org/docker/ojs/-/commit/f4f33f370e7c765b599868f0ca701898c875b47f, but not in stable-3_4_0 branch)
sed -i 's:/tmp/ojs.config.inc.php:/tmp/config.inc.php:' /usr/local/bin/ojs-variable

# Set config variables using env variables https://github.com/pkp/ojs/blob/main/config.TEMPLATE.inc.php
echo "Updating OJS config based on env variables..."
declare -A configVariable
configVariable["base_url"]=$WEBSITE_HOSTNAME 
configVariable["restful_urls"]="On"
configVariable["host"]=$OJS_DB_HOST
configVariable["username"]=$OJS_DB_USER
configVariable["password"]=$OJS_DB_PASSWORD
configVariable["name"]=$OJS_DB_NAME

for key in "${!configVariable[@]}"; do
  ojs-variable $key ${configVariable[$key]}
done

chmod +x /usr/local/bin/ojs-start
ojs-start