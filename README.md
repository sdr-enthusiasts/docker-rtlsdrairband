# docker-rtlsdrairband

Docker container to run [RTLSDR-Airband](https://github.com/szpajder/RTLSDR-Airband) alongside [Icecast](https://icecast.org). Builds and runs on `arm64` built for but not tested on `amd64` (see below).

This container runs an Icecast audio server that RTLSDR-Airband can connect to so that you can use an RTLSDR dongle to listen to Air Traffic Control VHF radio communications via a web browser or audio playback program.

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64 (Builds, untested. If it works for you let me know!)
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
  rtlsdirairband:
    image: fredclausen/rtlsdrairband
    tty: true
    container_name: rtlsdrairband
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
| ICECAST_HOSTNAME | The hostname or IP used to reach the icecast server. Used to show correct URLs for the streams on the web interface | No | localhost |
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
| STATION1_FREQS| If you are setting `multichannel` for your mode, enter a single frequency. If you are setting mode as `scan`, enter a comma separated list of frequencies you want to scan. Full formatting of the frequencies can be found [here](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuring-channels-for-multichannel-mode) | Yes | Unset |
| STATION1_NAME | The name of your stream | No | Tower |
| STATION1_GENRE | The genre of your stream | No | ATC |
| STATION1_SHOWMETADATA | If not set, the icecast server will receive updated metadata (either frequency or a specific label) of the frequency that is being received, and will show in playback clients. It might be adventageous to disable this because updated metadata will clutter up the icecast server logs. To disable, set to any value. Not applicable to multichannel mode | No | true |
| STATION1_LABELS | If STATION1_SHOWMETADATA is set to true, you can set this variable to a comma separated list of labels associated with the frequencies you are listening to. If set, the metadata on the icecast server will be updated to show the label associated with the frequency that is currently being received. If not set, the icecast metadata will be updated with the frequency. See [the RTSLDR-Airband manual](https://github.com/szpajder/RTLSDR-Airband/wiki/Icecast-metadata-updates-in-scan-mode) for more information. | No | Not set |
| STATION1_MOUNTPOINT | The custom part of the stream URL. Streams will be accessable at "serverip:8000/STATION1_MOUNTPOINT" | No | GND.mp3 |

## Accessing the Web Interface

The web interface for the container can be found at `containerip:8000`

## TODO

* Multiarch support
* More than one stream from the container
* Disable Icecast if desired and allow connections to a remote Icecast server


## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/fredclausen/docker-rtlsdrairband/issues) on the project's GitHub.
