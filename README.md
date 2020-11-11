# docker-rtlsdrairband

Docker container to run [RTLSDR-Airban](https://github.com/szpajder/RTLSDR-Airband) alongside [Icecast](https://icecast.org). Builds and runs on `arm64`(see below).

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

Icecase

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| ICECAST_SOURCE_PASSWORD | The password used for devices to provide Icecast with a stream. | No | rtlsdrairband |
| ICECAST_ADMIN_PASSWORD | The password used to log in to the admin interface. | No | rtlsdrairband" |
| ICECAST_ADMIN_USERNAME | The username used to log in to the admin interface | No | admin
| ICECAST_ADMIN_EMAIL | Admin email shown in the web interface. | No | test@test.com" |
| ICECAST_LOCATION | Location of server | No | earth |
| ICECAST_HOSTNAME | The hostname or IP used to reach the icecast server. Used to show correct URLs for the streams on the web interface | localhost |
| ICECAST_MAX_CLIENTS | Maximum listeners | No | 100 |
| ICECAST_MAX_SOURCES | Maximum number of clients that can provide a stream to the server | No | 4 |


## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/mikenye/docker-adsbhub/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
