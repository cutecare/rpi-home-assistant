[![lroguet/rpi-home-assistant](https://img.shields.io/docker/pulls/lroguet/rpi-home-assistant.svg)](https://hub.docker.com/r/lroguet/rpi-home-assistant/)
[![lroguet/rpi-home-assistant](https://images.microbadger.com/badges/version/lroguet/rpi-home-assistant.svg)](https://hub.docker.com/r/lroguet/rpi-home-assistant/) [![lroguet/rpi-home-assistant](https://images.microbadger.com/badges/image/lroguet/rpi-home-assistant.svg)](https://hub.docker.com/r/lroguet/rpi-home-assistant/)

# Home Assistant Docker image for Raspberry Pi

## Description
Generate a Dockerfile, build a Raspberry Pi compatible Docker image with [Home Assistant](https://home-assistant.io/) and push it to https://hub.docker.com.

## Build & push

*Note. You may want to update the `DOCKER_IMAGE_NAME` variable at the beginning of the `build.sh` script to build a custom Docker image and push it to your own Docker repository.*

### Prerequisite

sudo apt-get install jq curl
*Note. Install docker

### Latest version
To build a Docker image with the version of Home Assistant found at https://pypi.python.org/pypi/homeassistant/json just run `./build.sh`

*Note. This build case requires you have 'jq' installed.*

### Specific version
To build a Docker image with a specific version of Home Assistant run `./build.sh x.y.z` (`./build.sh 0.23.1` for example).

## Simple usage
`sudo mkdir /home/home-assistant`

`cd /home/home-assistant`

### Docker setup
`sudo wget -O package.deb https://download.docker.com/linux/raspbian/dists/jessie/pool/stable/armhf/docker-ce_17.09.0~ce-0~raspbian_armhf.deb`

`sudo dpkg -i /home/home-assistant/package.deb`

### Home Assistant setup
`sudo docker run -d --name hass --restart unless-stopped -p 8123:8123 --net=host -v /home/home-assistant:/config -v /etc/localtime:/etc/localtime:ro lroguet/rpi-home-assistant:latest`

## Logs
`sudo docker logs hass`

## Enable Bluetooth module
`sudo apt-get install rfkill` 
`sudo rfkill unblock all` 
`sudo systemctl restart bluetooth` 
`hciconfig`

## Links
* [Home Assistant, Docker & a Raspberry Pi](https://fourteenislands.io/home-assistant-docker-and-a-raspberry-pi/)
* [Docker public repository](https://hub.docker.com/r/lroguet/rpi-home-assistant/)
* [Home Assistant](https://home-assistant.io/)
