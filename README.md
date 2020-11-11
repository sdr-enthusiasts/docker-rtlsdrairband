# docker-rtlsdrairband

Docker container to run [RTLSDR-Airband](https://github.com/szpajder/RTLSDR-Airband) alongside [Icecast](https://icecast.org). Builds and runs on `arm64`(see below).

This container runs an Icecast audio server that RTLSDR-Airband can connect to so that you can use an RTLSDR dongle to listen to Air Traffic Control VHF radio communications via a web browser or audio playback program.

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64 (COMING SOON)
* `arm32v7`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3) (COMING SOON)
* `arm64`: ARMv8 64-bit (RPi 4 64-bit OSes)

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name rtlsdr-airband \
 -p 8000:8000 \
 -e STATION1_FREQS=123.9 \
 --device /dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER:/dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER \
fredclausen/rtlsdrairband
```

You should obviously replace `STATION1_FREQS` with a frequency you wish to monitor and the /dev/bus/usb path to your RTLSDR dongle.

## Up-and-Running with Docker Compose

```yaml
version: '2.0'

services:
  adsbhub:
    image: mikenye/adsbhub:latest
    tty: true
    container_name: adsbhub
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    ports:
      - 8080:8080
    environment:
      - STATION1_FREQS=123.9
```

## Ports

Port 8000 is exposed in this container.

## Environment variables

There are quite a few configuration options this container can accept. 

### Icecast

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| ICECAST_ADMIN_PASSWORD | The password used to log in to the admin interface. | No | rtlsdrairband |
| ICECAST_ADMIN_USERNAME | The username used to log in to the admin interface | No | admin
| ICECAST_ADMIN_EMAIL | Admin email shown in the web interface. | No | test@test.com |
| ICECAST_LOCATION | Location of server | No | earth |
| ICECAST_HOSTNAME | The hostname or IP used to reach the icecast server. Used to show correct URLs for the streams on the web interface | localhost |
| ICECAST_MAX_CLIENTS | Maximum listeners | No | 100 |
| ICECAST_MAX_SOURCES | Maximum number of clients that can provide a stream to the server | No | 4 |

### RTLSDR-Airband

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| STATION1_RADIO_TYPE | Type of dongle that is providing the radio tuning. Right now, only rtlsdr is usable. If you need something else supported, let me know | No | rtlsdr | 
| STATION1_GAIN | Gain setting for the RTLSDR dongle | No | 25 |
| STATION1_CORRECTION | Use this if your dongle has a non-zero frequency tuning error, which requires correcting. Put correction value in ppm here. If the dongle tunes too high, this value shall be positive, negative otherwise. | No | 0 |
| STATION1_SERIAL | Used to have rtlsdr-airband use the correct dongle if more than one present. Enter the serial of the dongle to be used | No | Unset |
| STATION1_MODE | If you are tuning a single frequency, set multichannel. If you are tuning more than one, set as scan | No | multichannel |
| STATION1_FREQS| If you are setting `multichannel` for your mode, enter a single frequency. If you are setting mode as `scan`, enter a comma separated list of frequencies you want to scan. Full formatting of the numbers can be found [here](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuring-channels-for-multichannel-mode) | Yes | Unset |
| STATION1_NAME | The name of your stream | No | Tower |
| STATION1_GENRE | The genre of your stream | No | ATC |
| STATION1_MOUNTPOINT | The custom part of the stream URL. Streams will be accesable at "serverip:8000/STATION1_MOUNTPOINT.m3u" | No | GND.mp3 |

## Accessing the Web Interface

The web interface for the container can be found at `containerip:8000`

## TODO

* Multiarch support
* More than one stream from the container


## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/fredclausen/docker-rtlsdrairband/issues) on the project's GitHub.
