FROM alpine:3.18

LABEL maintainer="Public Knowledge Project <marc.bria@gmail.com>"

WORKDIR /var/www/html

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1  \
	SERVERNAME="localhost"      \
	HTTPS="on"                  \
	OJS_VERSION=stable-3_4_0 \
	OJS_CLI_INSTALL="1"         \
	OJS_WEB_CONF="/etc/apache2/conf.d/ojs.conf"	\
	OJS_CONF="/var/www/html/config.inc.php" \
	SAVED_OJS_CONF="/home/config.inc.php"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php/8.1

# Basic packages
ENV PACKAGES 			\
	apache2 		\
	apache2-ssl 		\
	apache2-utils 		\
	ca-certificates 	\
	curl 			\
	ttf-freefont		\
	dcron 			\
	patch			\
	php81			\
	php81-apache2		\
	runit			\
	nano            \
	bash			\
	git

# PHP extensions
ENV PHP_EXTENSIONS		\
	php81-bcmath		\
	php81-bz2		\
	php81-calendar		\
	php81-ctype		\
	php81-curl		\
	php81-dom		\
	php81-exif		\
	php81-fileinfo		\
	php81-ftp		\
	php81-gd		\
	php81-gettext		\
	php81-intl		\
	php81-iconv		\
        gnu-libiconv            \
	php81-json		\
	php81-mbstring		\
	php81-mysqli		\
	php81-opcache		\
	php81-openssl		\
	php81-pdo_mysql		\
	php81-phar		\
	php81-posix		\
	php81-session		\
	php81-shmop		\
	php81-simplexml		\
	php81-sockets		\
	php81-sysvmsg		\
	php81-sysvsem		\
	php81-sysvshm		\
	php81-tokenizer		\
	php81-xml		\
	php81-xmlreader		\
	php81-xmlwriter		\
	php81-zip		\
	php81-zlib

# Required to build OJS:
ENV BUILDERS 		\
	git 			\
	nodejs 			\
	npm

# To make a smaller image, we start with the copy.
# This let us joining runs in a single layer.
COPY exclude.list /tmp/exclude.list

# Add build arguments for Git credentials
ARG GIT_USERNAME
ARG GIT_EMAIL
ARG GIT_TOKEN

RUN set -xe \
	&& apk add --no-cache --virtual .build-deps $BUILDERS \
	&& apk add --no-cache $PACKAGES \
	&& apk add --no-cache $PHP_EXTENSIONS \
        && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/community/ gnu-libiconv=1.17-r1 \
		# Configure Git with provided credentials
    && git config --global user.name "${GIT_USERNAME}" \
    && git config --global user.email "${GIT_EMAIL}" \
    && git config --global credential.helper store \
    && echo "https://${GIT_USERNAME}:${GIT_TOKEN}@github.com" > ~/.git-credentials \
	# Building OJS:
    # Configure and download code from git
	&& git config --global url.https://.insteadOf git:// \
	&& git config --global advice.detachedHead false \
	&& git clone --depth 1 --single-branch --branch $OJS_VERSION --progress https://github.com/pkp/ojs.git . \
	&& git submodule update --init --recursive >/dev/null \
      # Composer vudu:
 	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer.phar \
	# To avoid timeouts with gitHub we use tokens:
	# TODO: Replace personal token by an official one.
 	# && composer.phar config -g github-oauth.github.com <yourAPIkeyHere> \
      # Install Composer Deps:
	&& for i in $(find . -name composer.json); do \
	   COMPOSERWD=$(echo $i | sed 's/composer.json//'); \
	   echo -n " - $COMPOSERWD ... "; \
	   composer.phar --working-dir=$COMPOSERWD install --no-dev; \
	   echo "Done"; \
	done \
      # Node joins to the party:
	&& npm ci -y \
        && NODE_OPTIONS=--openssl-legacy-provider npm run build \
# Create directories
 	&& mkdir -p /var/www/files /run/apache2  \
	&& cp config.TEMPLATE.inc.php config.inc.php \
	&& chown -R apache:apache /var/www/* \
# Prepare freefont for captcha 
	&& ln -s /usr/share/fonts/TTF/FreeSerif.ttf /usr/share/fonts/FreeSerif.ttf \
# Prepare crontab
	&& echo "0 * * * *   ojs-run-scheduled" | crontab - \
# Prepare httpd.conf
	&& sed -i -e '\#<Directory />#,\#</Directory>#d' /etc/apache2/httpd.conf \
	&& sed -i -e "s/^ServerSignature.*/ServerSignature Off/" /etc/apache2/httpd.conf \
# Clear the image (list of files to be deleted in exclude.list).
	&& cd /var/www/html \
 	&& rm -rf $(cat /tmp/exclude.list) \
	&& apk del --no-cache .build-deps \
	&& rm -rf /tmp/* \
	&& rm -rf /root/.cache/* \
# Some folders are not required (as .git .travis.yml test .gitignore .gitmodules ...)
	&& find . -name ".git" -exec rm -Rf '{}' \; \
	&& find . -name ".travis.yml" -exec rm -Rf '{}' \; \
	&& find . -name "test" -exec rm -Rf '{}' \; \
	&& find . \( -name .gitignore -o -name .gitmodules -o -name .keepme \) -exec rm -Rf '{}' \; \
# Remove unnecessary (and annoying) files and folders
	&& rm -rf /var/www/html/public \
	&& rm config.TEMPLATE.inc.php \
	&& rm -rf /var/www/html/files

# Fix mixed content issue
COPY .htaccess /var/www/html/
RUN sed -i 's@^#LoadModule headers_module modules/mod_headers\.so@LoadModule headers_module modules/mod_headers.so@' /etc/apache2/httpd.conf
RUN sed -i "s/\$this->_protocol = (!isset(\$_SERVER\['HTTPS'\]) || strtolower_codesafe(\$_SERVER\['HTTPS'\]) != 'on') ? 'http' : 'https'/\$this->_protocol = 'https'/" /var/www/html/lib/pkp/classes/core/PKPRequest.php

# Enable ssh
COPY sshd_config /etc/ssh/
COPY entrypoint.sh /var/www/html/

RUN apk add openssh \
       && echo "root:Docker!" | chpasswd \
                     && chmod +x /var/www/html/entrypoint.sh \
                     && cd /etc/ssh/ \
                     && ssh-keygen -A

# Add themes
ADD plugins/themes /var/www/html/plugins/themes

# Add SSL cert option for DB Connection (replace files in pkp lib)
COPY ssl/PKPContainer.php /var/www/html/lib/pkp/classes/core
COPY ssl/PKPInstall.php /var/www/html/lib/pkp/classes/install
ADD ssl /var/www/html/ssl

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

COPY root/ /

EXPOSE 8000 2222

EXPOSE 80 
EXPOSE 443

# VOLUME [ "/var/www/files", "/var/www/html/public" ]

ENTRYPOINT [ "/var/www/html/entrypoint.sh" ] 