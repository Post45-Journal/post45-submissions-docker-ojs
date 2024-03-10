

https://thenewstack.io/how-to-trigger-github-actions-on-submodule-updates/


# dockerfiles & github actions
[Dockerfile & Github Actions](https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions)

docker build in github actions: https://stackoverflow.com/questions/61154750/use-local-dockerfile-in-a-github-action



https://stackoverflow.com/questions/75490598/how-to-host-docker-compose-app-on-azure-app-service

# Tutorial for Docker Compose config
https://learn.microsoft.com/en-us/azure/app-service/tutorial-multi-container-app#connect-to-production-database

- Need to set up DB and redis
- part of that involves customizing the docker image


## Instructions on adding SSH from Microsoft forum
- + Examples: https://github.com/azureossd/docker-container-ssh-examples


### Docker File: 

FROM node:lts-alpine
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*","sshd_config","entrypoint.sh", "./"]
RUN npm install --production --silent && mv node_modules ../
COPY sshd_config /etc/ssh/
 

# Start and enable SSH
RUN apk add openssh \
       && echo "root:Docker!" | chpasswd \
                     && chmod +x //usr/src/app/entrypoint.sh \
                     && cd /etc/ssh/ \
                     && ssh-keygen -A
COPY . .
EXPOSE 3000 2222
#RUN chown -R node /usr/src/app
#USER node
ENTRYPOINT [ "/usr/src/app/entrypoint.sh" ] 

 
### sshd_config:
 
<!-- Port                                    2222
ListenAddress                  0.0.0.0
LoginGraceTime                             180
X11Forwarding                yes
Ciphers aes128-cbc,3des-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr
MACs hmac-sha1,hmac-sha1-96
StrictModes                     yes
SyslogFacility                    DAEMON
PasswordAuthentication             yes
PermitEmptyPasswords               no
PermitRootLogin             yes
Subsystem sftp internal-sftp -->
 
<!-- ### entrypoint.sh

#!/bin/sh
set -e
 
# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)
 
echo "Starting SSH ..."
/usr/sbin/sshd
exec npm start -->
 
 


https://github.com/actions/checkout/discussions/928#discussioncomment-3871262

https://github.com/actions/checkout/issues/116#issuecomment-644419389


https://thenewstack.io/how-to-trigger-github-actions-on-submodule-updates/#:~:text=First%2C%20you%20can%20choose%20how,out%20on%20the%20parent%20REPOSITORY%20.