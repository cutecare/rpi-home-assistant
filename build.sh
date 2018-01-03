#!/bin/bash

HA_LATEST=false
DOCKER_IMAGE_NAME="cutecare/rpi-home-assistant"
RASPIAN_RELEASE="stretch"

log() {
   now=$(date +"%Y%m%d-%H%M%S")
   echo "$now - $*" >> /var/log/home-assistant/docker-build.log
}

log ">>--------------------->>"

## #####################################################################
## Home Assistant version
## #####################################################################
if [ "$1" != "" ]; then
   # Provided as an argument
   HA_VERSION=$1
   log "Docker image with Home Assistant $HA_VERSION"
else
   _HA_VERSION="$(cat /var/log/home-assistant/docker-build.version)"
   HA_VERSION="$(curl 'https://pypi.python.org/pypi/homeassistant/json' | jq '.info.version' | tr -d '"')"
   HA_LATEST=true
   log "Docker image with Home Assistant 'latest' (version $HA_VERSION)"
fi

## #####################################################################
## For hourly (not parameterized) builds (crontab)
## Do nothing: we're trying to build & push the same version again
## #####################################################################
if [ "$HA_LATEST" == true ] && [ "$HA_VERSION" == "$_HA_VERSION" ]; then
   log "Docker image with Home Assistant $HA_VERSION has already been built & pushed"
   log ">>--------------------->>"
   exit 0
fi

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
      apt-utils build-essential python3-dev python3-pip python3-setuptools \
      libffi-dev libpython-dev libssl-dev \
      libudev-dev bluetooth \
      net-tools rfkill nmap iputils-ping \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Mouting point for the user's configuration
VOLUME /config

# Install Home Assistant
RUN pip3 install wheel
RUN pip3 install xmltodict
RUN pip3 install homeassistant
RUN pip3 install sqlalchemy
RUN pip3 install netdisco
RUN pip3 install aiohttp_cors

# Install gattlib
RUN ln -s /usr/lib/arm-linux-gnueabihf/libboost_python-py35.so /usr/lib/arm-linux-gnueabihf/libboost_python-py34.so
RUN apt-get update
RUN apt-get -y install pkg-config libboost-python-dev libboost-thread-dev libbluetooth-dev libglib2.0-dev python-dev
RUN pip3 install gattlib
RUN pip3 install cutecare-py

#Install and configure cron
RUN apt-get install -y cron
RUN (sudo crontab -u root -l 2>/dev/null ; echo "*/10 * * * * root service bluetooth restart")| sudo crontab -u root -
RUN service cron restart

# Switch on cutecare-platform branch
RUN apt-get install -y git
RUN git clone -b cutecare-platform https://github.com/cutecare/home-assistant.git /config/home-assistant
RUN rm -r /usr/local/lib/python3.5/dist-packages/homeassistant/components
RUN ln -s /config/home-assistant/homeassistant/components /usr/local/lib/python3.5/dist-packages/homeassistant/components

# Start Home Assistant
CMD [ "python3", "-m", "homeassistant", "--config", "/config" ]
_EOF_

## #####################################################################
## Build the Docker image, tag and push to https://hub.docker.com/
## #####################################################################
log "Building $DOCKER_IMAGE_NAME:$HA_VERSION"
## Force-pull the base image
docker pull resin/rpi-raspbian:$RASPIAN_RELEASE
docker build -t $DOCKER_IMAGE_NAME:$HA_VERSION .

log "Pushing $DOCKER_IMAGE_NAME:$HA_VERSION"
docker push $DOCKER_IMAGE_NAME:$HA_VERSION

if [ "$HA_LATEST" = true ]; then
   log "Tagging $DOCKER_IMAGE_NAME:$HA_VERSION with latest"
   docker tag $DOCKER_IMAGE_NAME:$HA_VERSION $DOCKER_IMAGE_NAME:latest
   log "Pushing $DOCKER_IMAGE_NAME:latest"
   docker push $DOCKER_IMAGE_NAME:latest
   echo $HA_VERSION > /var/log/home-assistant/docker-build.version
fi

log ">>--------------------->>"
