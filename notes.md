

https://thenewstack.io/how-to-trigger-github-actions-on-submodule-updates/


# dockerfiles & github actions
[Dockerfile & Github Actions](https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions)

docker build in github actions: https://stackoverflow.com/questions/61154750/use-local-dockerfile-in-a-github-action



https://stackoverflow.com/questions/75490598/how-to-host-docker-compose-app-on-azure-app-service

# Tutorial for Docker Compose config
https://learn.microsoft.com/en-us/azure/app-service/tutorial-multi-container-app#connect-to-production-database

- Need to set up DB and redis
- part of that involves customizing the docker image


## Adding SSH to Azure App Service Container
- + Examples: https://github.com/azureossd/docker-container-ssh-examples
- [Troubleshooting](https://azureossd.github.io/2022/04/27/2022-Enabling-SSH-on-Linux-Web-App-for-Containers/index.html#troubleshooting)


https://github.com/actions/checkout/discussions/928#discussioncomment-3871262

https://github.com/actions/checkout/issues/116#issuecomment-644419389


https://thenewstack.io/how-to-trigger-github-actions-on-submodule-updates/#:~:text=First%2C%20you%20can%20choose%20how,out%20on%20the%20parent%20REPOSITORY%20.


## Mixed Content issue
Need to enable apache's mod_headers
then add the following to .htaccess

<ifModule mod_headers.c>
Header always set Content-Security-Policy "upgrade-insecure-requests;"
</IfModule>