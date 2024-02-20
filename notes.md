

https://thenewstack.io/how-to-trigger-github-actions-on-submodule-updates/


# dockerfiles & github actions
[Dockerfile & Github Actions](https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions)

docker build in github actions: https://stackoverflow.com/questions/61154750/use-local-dockerfile-in-a-github-action



https://stackoverflow.com/questions/75490598/how-to-host-docker-compose-app-on-azure-app-service

# Tutorial for Docker Compose config
https://learn.microsoft.com/en-us/azure/app-service/tutorial-multi-container-app#connect-to-production-database

- Need to set up DB and redis
- part of that involves customizing the docker image




Docker File: 

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
 
