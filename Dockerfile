# Première partie du Dockerfile (main)
FROM --platform=$BUILDPLATFORM alpine:edge as main

LABEL maintainer="Jorge Arco <jorge.arcoma@gmail.com>" 
LABEL org.opencontainers.image.title="Symfony 7 & PHP 8.3" 

RUN apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/main add \
    icu-libs \
    && apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community add \
    # Current packages don't exist in other repositories
    libavif \
    gnu-libiconv \
    shadow \
    # Packages
    tini \
    php83 \
    php83-dev \
    php83-common \
    php83-gd \
    php83-xmlreader \
    php83-bcmath \
    php83-ctype \
    php83-curl \
    php83-exif \
    php83-iconv \
    php83-intl \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-pcntl \
    php83-phar \
    php83-session \
    php83-xml \
    php83-xsl \
    php83-zip \
    php83-zlib \
    php83-dom \
    php83-fpm \
    php83-sodium \
    php83-tokenizer \
    # Iconv Fix
    php83-pecl-apcu \
    && ln -sf /usr/bin/php83 /usr/bin/php

ADD rootfs /

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/usr/sbin/php-fpm83", "-R", "--nodaemonize"]

EXPOSE 8000

# Seconde partie du Dockerfile (dev)
FROM --platform=$BUILDPLATFORM main as dev

RUN adduser -D -s /bin/zsh toto
ARG USER=toto
ARG PASSWORD=toto

ARG COMPOSER_VERSION=2.5.1

RUN apk add -U --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/   \
        php83-pear \
        openssh \
        supervisor \
        autoconf \
        git \
        curl \
        bash \
        wget \
        powerline-extra-symbols \
        nodejs \
         npm \
         lsd \
        make \
        zip \
        php83-xdebug \
    # Delete APK cache.
    && rm -rf /var/cache/apk/* \
    # Create ssh user for dev.
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
    && echo "${USER}:${PASSWORD}" | chpasswd \
    && ssh-keygen -A \
    # Download composer.
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} 

# Symfony CLI
RUN curl -sS https://get.symfony.com/cli/installer -o installer.sh && \
    bash installer.sh && \
    mv /root/.symfony5/bin/symfony /usr/local/bin && \
    rm installer.sh


   


RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" \
    -t https://github.com/denysdovhan/spaceship-prompt \
    -a 'SPACESHIP_PROMPT_ADD_NEWLINE="false"' \
    -a 'SPACESHIP_PROMPT_SEPARATE_LINE="false"' \
    -p git \
    -p gitfast \
    -p symfony \
    -p ssh-agent \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting 


RUN mkdir -p ~/.ssh

RUN npm install --global yarn

RUN git config --global user.email "antonycharier@gmail.com" \
    &&  git config --global user.name "CodingBDX"

ADD devfs /


RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

RUN echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc && \
    echo 'POWERLEVEL10K_MODE="nerdfont-complete"' >> ~/.zshrc && \
    echo 'POWERLEVEL10K_CUSTOM_NERD_FONT_ICON="echo -n ''\ue5fe''"' >> ~/.zshrc \
    echo 'POWERLEVEL10K_DISABLE_RPROMPT=true' >> ~/.zshrc \
echo 'POWERLEVEL10K_PROMPT_ON_NEWLINE=true' >> ~/.zshrc \
echo 'POWERLEVEL10K_MULTILINE_LAST_PROMPT_PREFIX=""' >> ~/.zshrc \
echo 'POWERLEVEL10K_MULTILINE_FIRST_PROMPT_PREFIX=""' >> ~/.zshrc \
echo 'DEFAULT_USER=$USER' >> ~/.zshrc

RUN echo 'plugins=(docker zsh-completions docker-compose git zsh-autosuggestions sudo)' >> ~/.zshrc

RUN \
  NERDS_FONT_VERSION="2.1.0" \
  && FONT_DIR=/usr/share/fonts \
  && FIRA_CODE_URL=https://github.com/ryanoasis/nerd-fonts/raw/${NERDS_FONT_VERSION}/patched-fonts/FiraCode \
  && FIRA_CODE_LIGHT_DOWNLOAD_SHA256="5e0e3b18b99fc50361a93d7eb1bfe7ed7618769f4db279be0ef1f00c5b9607d6" \
  && FIRA_CODE_REGULAR_DOWNLOAD_SHA256="3771e47c48eb273c60337955f9b33d95bd874d60d52a1ba3dbed924f692403b3" \
  && FIRA_CODE_MEDIUM_DOWNLOAD_SHA256="42dc83c9173550804a8ba2346b13ee1baa72ab09a14826d1418d519d58cd6768" \
  && FIRA_CODE_BOLD_DOWNLOAD_SHA256="060d4572525972b6959899931b8685b89984f3b94f74c2c8c6c18dba5c98c2fe" \
  && FIRA_CODE_RETINA_DOWNLOAD_SHA256="e254b08798d59ac7d02000a3fda0eac1facad093685e705ac8dd4bd0f4961b0b" \
  && mkdir -p $FONT_DIR \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Light/complete/Fura%20Code%20Light%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Regular/complete/Fura%20Code%20Regular%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Medium/complete/Fura%20Code%20Medium%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Bold/complete/Fura%20Code%20Bold%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Retina/complete/Fura%20Code%20Retina%20Nerd%20Font%20Complete.ttf \
  && echo "$FIRA_CODE_LIGHT_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Light Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_REGULAR_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Regular Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_MEDIUM_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Medium Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_BOLD_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Bold Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_RETINA_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Retina Nerd Font Complete.ttf" | sha256sum -c -
  


RUN echo 'alias ls="lsd"' >> ~/.zshrc

RUN sed -i 's,/bin/ash,/bin/zsh,g' /etc/passwd






# Définir le répertoire de travail (par exemple)
WORKDIR /var/www/html/


CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord/conf.d/supervisord.conf"]

EXPOSE 8008
EXPOSE 8007

