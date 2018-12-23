#!/bin/bash

HA_VERSION="latest"
DOCKER_IMAGE_NAME="cutecare/rpi-home-assistant"
RASPIAN_RELEASE="stretch"

## #####################################################################
## Generate the Dockerfile
## #####################################################################
cat << _EOF_ > Dockerfile
FROM resin/rpi-raspbian:$RASPIAN_RELEASE
MAINTAINER Evgeny Savitsky <evgeny.savitsky@gmail.com>

# Base layer
ENV ARCH=arm
ENV CROSS_COMPILE=/usr/bin/

# Install required packages
RUN apt-get update && \
    apt-get install --no-install-recommends \
      curl apt-utils build-essential python3-dev python3-pip python3-setuptools \
      libffi-dev libpython-dev libssl-dev \
      libudev-dev bluetooth bluez-hcidump \
      net-tools rfkill nmap iputils-ping ffmpeg \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ln -s /usr/lib/arm-linux-gnueabihf/libboost_python-py35.so /usr/lib/arm-linux-gnueabihf/libboost_python-py34.so && \
   apt-get update && apt-get -y install git cron pkg-config libboost-python-dev libboost-thread-dev libbluetooth-dev libglib2.0-dev python-dev

# Install Python modules
RUN pip3 install wheel && pip3 install xmltodict bluepy homeassistant netdisco sqlalchemy home-assistant-frontend psutil

# Install nodejs
RUN apt-get -y install curl gnupg gnupg2 && \
   curl -sL https://deb.nodesource.com/setup_11.x | bash - && \
   apt-get -y install nodejs
   
# Install wcode web-editor
RUN git clone -b cutecare https://github.com/cutecare/wcode.git /home/wcode && \
   npm install --prefix /home/wcode nodejs express

# Override homeassistant source code
RUN (rm -fr /usr/local/lib/python3.6/dist-packages/homeassistant || true) && \
   (rm -fr /usr/local/lib/python3.5/dist-packages/homeassistant || true)

# Switch on cutecare-platform branch
RUN git clone -b cutecare-platform https://github.com/cutecare/home-assistant.git /home/home-assistant  && \
   (pip3 install -r /home/home-assistant/homeassistant/package_constraints.txt 2> /dev/null || true)

RUN ln -s /home/home-assistant/homeassistant /usr/local/lib/python3.5/dist-packages/homeassistant

# Run Home Assistant
CMD ([ -f /config/configuration.yaml ] && echo "Skip default config" || git clone https://github.com/cutecare/hass-cutecare-config.git /config) && \
   (nohup npm start --prefix /home/wcode -- --headless --port 8080 /config > /config/wcode.log &) && \
   python3 -m homeassistant --config=/config

# Mouting point for the user's configuration
VOLUME /config

_EOF_

## #####################################################################
## Build the Docker image, tag and push to https://hub.docker.com/
## #####################################################################

## Force-pull the base image
docker pull resin/rpi-raspbian:$RASPIAN_RELEASE
docker build -t $DOCKER_IMAGE_NAME:$HA_VERSION .

docker push $DOCKER_IMAGE_NAME:$HA_VERSION

