# Docker-образ Home Assistant

Этот образ специальным образом подготовлен для установки Home Assistant на Raspberry Pi в виде Docker-контейнера, что существенно упрощает установку и обновление ПО. В образе выполняется установка необходимого дополнительного ПО, решаются конфликты зависимостей и т.п. Docker-образ изолирует Home Assistant от другого установленного ПО, таким образом, на одном Raspberry Pi вы можете разместить совершенно различный софт, который не будет мешать друг другу.

## Использование образа для установки Home Assistant

После установки ОС Raspbian в каком-либо виде, необходимо открыть терминал или подключиться к ОС посредством ssh и выполнить следующие команды:

`sudo -s`

`sudo apt-get update && sudo apt-get -y upgrade` 

### Установка Docker на Rasberry Pi

`sudo wget --secure-protocol=TLSv1 --no-check-certificate -O package.deb https://download.docker.com/linux/raspbian/dists/jessie/pool/stable/armhf/docker-ce_17.09.0~ce-0~raspbian_armhf.deb`

`sudo dpkg -i /home/home-assistant/package.deb`

`mkdir /home/home-assistant`

`cd /home/home-assistant`

### Установка Home Assistant в форме Docker-контейнера

Параметры контейнера (hass) указаны таким образом, чтобы Home Assistant запускался при старте ОС, веб-интерфейс открывался по порту 8123, конфигурационные файлы находились в каталоге /home/home-assistant

`sudo docker run -d --name hass --restart unless-stopped -p 8123:8123 --net=host -v /home/home-assistant:/config -v /etc/localtime:/etc/localtime:ro cutecare/rpi-home-assistant:latest`

## Просмотра логов Home Assistant

`sudo docker logs hass`

## Включение Bluetooth

По умолчанию модуль Bluetooth может быть отключен. Выполните команды ниже, чтобы снять блокировку с модуля.

`sudo apt-get install rfkill` 

`sudo rfkill unblock all` 

`sudo systemctl restart bluetooth` 

`hciconfig`

## Сборка и публикация образа

Вы можете доработать образ, добавив туда необходимых компонентов.

### Необходимое ПО

Сборку и публикацию образа можно выполнять, например, на [Ubuntu Studio](https://ubuntustudio.org/), установленной на ПК или в виде  [виртуальной машины](https://www.virtualbox.org/)

В зависимости от используемой ОС, выберите подходящий способ [установки Docker](https://docs.docker.com/engine/installation/) и установите его. Затем выполните следующие команды:

 `sudo -s`
 `apt-get install jq curl git` 
 `git clone https://github.com/cutecare/rpi-home-assistant.git`
 `./build.sh`
