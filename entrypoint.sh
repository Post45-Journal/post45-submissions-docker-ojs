#!/bin/sh
set -e

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)
 
echo "Starting SSH ..."
/usr/sbin/sshd

chsh root -s /bin/bash

chmod +x /usr/local/bin/ojs-variable
# Temporary fix for error in ojs-variable (fixed here https://gitlab.com/pkp-org/docker/ojs/-/commit/f4f33f370e7c765b599868f0ca701898c875b47f, but not in stable-3_4_0 branch)
sed -i 's:/tmp/ojs.config.inc.php:/tmp/config.inc.php:' /usr/local/bin/ojs-variable


chmod +x /usr/local/bin/ojs-start
ojs-start