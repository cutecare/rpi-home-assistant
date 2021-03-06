# Docker-образ Home Assistant + BLE

Этот образ специальным образом подготовлен для установки Home Assistant на Raspberry Pi в виде Docker-контейнера, что существенно упрощает установку и обновление ПО. В образе выполняется установка необходимого дополнительного ПО, решаются конфликты зависимостей и т.п. Docker-образ изолирует Home Assistant от другого установленного ПО, таким образом, на одном Raspberry Pi вы можете разместить совершенно различный софт, который не будет мешать друг другу.

После установки ОС Raspbian в каком-либо виде, необходимо открыть терминал или подключиться к ОС посредством ssh и выполнить следующие команды:

```
sudo -s
apt-get -y update && apt-get -y install docker-ce=18.06.1~ce~3-0~raspbian
mkdir /home/home-assistant
docker run -d --name hass --restart unless-stopped -p 8123:8123 -p 8080:8080 --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --net=host -v /home/home-assistant:/config --device=/dev/video0 -v /dev:/dev -v /etc/localtime:/etc/localtime:ro cutecare/rpi-home-assistant:latest
```

Параметры контейнера (hass) указаны таким образом, чтобы Home Assistant запускался при старте ОС, веб-интерфейс открывался по порту 8123, конфигурационные файлы находились в каталоге /home/home-assistant

### Отключение Swap

Чтобы сберечь ресурс SD-карты, отключим своп при помощи следующих команд:
```
sudo -s
dphys-swapfile swapoff && dphys-swapfile uninstall && update-rc.d dphys-swapfile remove
```

### Просмотр логов Home Assistant

```
sudo docker logs hass
```

Чтобы логи не съедали все место на диске необходимо ограничить их размер.
Сделать это можно следующим образом:

```
cat > /etc/docker/daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "2m",
        "max-file": "5"
    }
}
EOF
service docker restart
```

### Выполнение команд в образе Home Assistant

```
sudo docker exec hass echo 'hello from hass image'
```

## Включение Bluetooth

По умолчанию модуль Bluetooth может быть отключен. Выполните команды ниже, чтобы снять блокировку с модуля.

```
sudo -s
apt-get -y install rfkill
rfkill unblock all
systemctl restart bluetooth
hciconfig
```

# Сборка и публикация образа

Вы можете доработать образ, добавив туда необходимых компонентов. Сборка образа выполняется на Raspberry Pi. Перед публикацией образа в Docker Hub, необходимо в нем зарегистрироваться, а затем залогиниться командой:

```
docker login
```

В зависимости от используемой ОС, выберите подходящий способ [установки Docker](https://docs.docker.com/engine/installation/) и установите его. Затем выполните следующие команды:

```
sudo -s
apt-get -y install jq curl git
git clone https://github.com/cutecare/rpi-home-assistant.git
cd rpi-home-assistant
./build.sh
```

## Проверка установки образа

Проверку установки образа можно выполнить на [виртуальной машине](http://www.makeuseof.com/tag/emulate-raspberry-pi-pc/). Используйте, например, Ubuntu Studio для запуска эмулятора QEMU

Установите эмулятор QEMU, он необходим чтобы эмулировать Raspbian для процессора ARM

```
sudo apt-get install qemu-system
```

Скачайте дистрибутив [Raspbian](https://www.raspberrypi.org/downloads/raspbian/) и [образ ядра](https://github.com/dhruvvyas90/qemu-rpi-kernel), например,

```
curl https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.4.34-jessie
```

Распакуйте архив дистрибутива Raspbian и преобразуйте в образ QEMU

```
qemu-img convert -f raw -O qcow2 2017-11-29-raspbian-stretch-lite.img raspbian-stretch-lite.qcow
```

Увеличим размер файла с образом

```
qemu-img resize raspbian-stretch-lite.qcow +6G
```

И запустим эмуляцию

```
sudo qemu-system-arm -kernel ./kernel-qemu-4.4.34-jessie -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" -hda raspbian-stretch-lite.qcow -cpu arm1176 -m 256 -M versatilepb -no-reboot -redir tcp:2222::22 -redir tcp:8123::8123 -serial stdio -net nic -net user -net tap,ifname=vnet0,script=no,downscript=no
```

После запуска Raspbian можно подключиться к ОС по SSH и выполнить установку Docker и Docker-образа HASS

```
ssh -p2222 pi@localhost
```

Перед установкой рекомендуем изменить размер диска, иначе приложения могут не поместиться. Для этого используйте команду

```
sudo fdisk /dev/sda
```

и дальше следуйте [инструкциям](https://gist.github.com/larsks/3933980), после перезагрузки выполните команду

```
sudo resize2fs /dev/sda2
```
