# syntax=docker/dockerfile:1.4
FROM node:19-bullseye-slim

# make app folder
RUN mkdir -p /usr/local/share/twitchautomator \
    && chown -R node:node /usr/local/share/twitchautomator \
    && chmod -R 775 /usr/local/share/twitchautomator

# internal docker build args for build date and dev mode
ARG IS_DEV
ARG BUILD_DATE
ENV IS_DEV=${IS_DEV}
ENV VITE_IS_DEV=${IS_DEV}
ENV BUILD_DATE=${BUILD_DATE}
ENV VITE_BUILD_DATE=${BUILD_DATE}

# system packages
#RUN apk --no-cache add \
#    gcc g++ libc-dev git curl \
#    ca-certificates \
#    python3 py3-pip py3-wheel \
#    ffmpeg mediainfo \
#    util-linux busybox-initscripts procps gcompat \
#    libxml2-dev libxslt-dev python3-dev \
#    bash icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib fontconfig

RUN apt-get update && apt-get install -y \
    ffmpeg mediainfo \
    python3 python3-pip python3-wheel libxml2-dev libxslt-dev python3-dev \
    bash git curl unzip rclone \
    gnupg lsb-release \
    && apt-get clean

# copy over pipenv files and install dependencies for python
# WORKDIR /usr/local/share/twitchautomator
COPY ./Pipfile ./Pipfile.lock ./requirements.txt ./binaries.txt /usr/local/share/twitchautomator/
# install pipenv globally
RUN pip install pipenv && pip cache purge
# switch to node user to install pipenv dependencies
USER node 
ENV PATH="${PATH}:/home/node/.local/bin"
RUN cd /usr/local/share/twitchautomator && \
    pipenv install --deploy --ignore-pipfile --verbose && \
    pipenv --version && \
    pipenv run python --version && \
    pipenv run streamlink --version

USER root

# remove dev packages
RUN apt-get remove -y \
    libxml2-dev libxslt-dev python3-dev \
    && apt-get autoremove -y

# install yarn
# RUN npm install -g yarn
    
# libfontconfig1 can't be found

# pip packages
# COPY ./requirements.txt /tmp/requirements.txt
# RUN pip install -r /tmp/requirements.txt \
#     && rm /tmp/requirements.txt \
#     && pip cache purge

# common
COPY --chown=node:node --chmod=775 ./common /usr/local/share/twitchautomator/common

# chat dumper
COPY --chown=node:node --chmod=775 ./twitch-chat-dumper /usr/local/share/twitchautomator/twitch-chat-dumper
RUN cd /usr/local/share/twitchautomator/twitch-chat-dumper \
    && yarn \
    && yarn build \
    && rm -rf node_modules \
    && rm -rf .yarn/cache \
    && yarn cache clean --all

# vod player
COPY --chown=node:node --chmod=775 ./twitch-vod-chat /usr/local/share/twitchautomator/twitch-vod-chat
RUN cd /usr/local/share/twitchautomator/twitch-vod-chat \
    && yarn \
    && yarn build --base=/vodplayer \
    && yarn buildlib \
    && rm -rf node_modules \
    && rm -rf .yarn/cache \
    && yarn cache clean --all

# server
COPY --chown=node:node --chmod=775 ./server /usr/local/share/twitchautomator/server
RUN cd /usr/local/share/twitchautomator/server \
    && yarn \
    && yarn lint:ts \
    && yarn build \
    && yarn run generate-licenses \
    && rm -rf node_modules \
    && rm -rf .yarn/cache \
    && yarn cache clean --all

# client
COPY --chown=node:node --chmod=775 ./client-vue /usr/local/share/twitchautomator/client-vue
RUN cd /usr/local/share/twitchautomator/client-vue \
    && yarn \
    && yarn build \
    && yarn run generate-licenses \
    && rm -rf node_modules \
    && rm -rf .yarn/cache \
    && yarn cache clean --all

# copy rest
# COPY --chown=node:node --chmod=775 . /usr/local/share/twitchautomator/

# install dotnet for twitchdownloader
# ADD https://dot.net/v1/dotnet-install.sh /tmp/dotnet-install.sh
# RUN chmod +x /tmp/dotnet-install.sh && /tmp/dotnet-install.sh --channel 3.1 --verbose --install-dir /usr/share/dotnet
# --runtime dotnet

# download twitchdownloader, is this legal? lmao
COPY ./docker/fetch-tdl.sh /tmp/fetch-tdl.sh
RUN bash /tmp/fetch-tdl.sh
ENV TCD_TWITCHDOWNLOADER_PATH=/usr/local/bin/TwitchDownloaderCLI

# download ttv-lol-plugin
COPY ./docker/fetch-ttv-lol.sh /tmp/fetch-ttv-lol.sh
RUN bash /tmp/fetch-ttv-lol.sh

# application folder permissions
# seems like docker does not support recursive chown in the copy command
# so this is a workaround, doubling the layer size unfortunately.
# it also takes a very long time on slow storage
# RUN chown -c -R node:node /usr/local/share/twitchautomator && chmod -R 775 /usr/local/share/twitchautomator
# RUN chown -c -R node:node /usr/local/share/twitchautomator/data && chmod -R 775 /usr/local/share/twitchautomator/data

# make home folder
RUN mkdir -p /home/node && chown -R node:node /home/node
ENV HOME /home/node

# fonts
RUN mkdir /home/node/.fonts && chown node:node /home/node/.fonts
COPY ./docker/fonts /home/node/.fonts

# get certs
# RUN wget https://curl.haxx.se/ca/cacert.pem -O /tmp/cacert.pem

# Tailscale support
ENV TAILSCALE_ENABLE=false
ENV TAILSCALE_AUTH_KEY=""
ENV TAILSCALE_ENABLE_SSH=false
ENV TAILSCALE_HOSTNAME="LiveStreamDVR"

RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -c -s).gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -c -s).tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update && apt-get install tailscale && apt-get clean

COPY ./docker/tailscale/setup-tailscale.sh /usr/local/bin/setup-tailscale.sh
RUN chmod +x /usr/local/bin/setup-tailscale.sh
RUN /usr/local/bin/setup-tailscale.sh

COPY ./docker/tailscale/start-tailscale.sh /usr/local/bin/start-tailscale.sh
RUN chmod +x /usr/local/bin/start-tailscale.sh

# twitchautomator docker specific configs
ENV TCD_BIN_DIR=/usr/local/bin
ENV TCD_FFMPEG_PATH=/usr/bin/ffmpeg
ENV TCD_BIN_PATH_PYTHON=/usr/bin/python
ENV TCD_BIN_PATH_PYTHON3=/usr/bin/python3
ENV TCD_MEDIAINFO_PATH=/usr/bin/mediainfo
ENV TCD_NODE_PATH=/usr/local/bin/node
ENV TCD_DOCKER=1
ENV TCD_WEBSOCKET_ENABLED=1
# ENV TCD_CA_PATH=/tmp/cacert.pem
ENV TCD_SERVER_PORT=8080
ENV TCD_PYTHON_ENABLE_PIPENV=1

# USER node
WORKDIR /usr/local/share/twitchautomator/server

ENTRYPOINT [ "/usr/local/bin/start-tailscale.sh", ";", "yarn", "run", "start" ]
EXPOSE 8080