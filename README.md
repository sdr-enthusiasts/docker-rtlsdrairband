# docker-rtlsdrairband

Docker container to run [RTLSDR-Airband](https://github.com/szpajder/RTLSDR-Airband) alongside [Icecast](https://icecast.org). Builds and runs on `arm64`. A container is provided for, but not tested, `amd64` and `arm32v7` (see below).

This container runs an Icecast audio server that RTLSDR-Airband can connect to so that you can use an RTLSDR dongle to listen to Air Traffic Control VHF radio communications via a web browser or audio playback program.

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64 (Builds, untested. If it works for you let me know!)
* `arm32v7`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3) (Builds, untested. If it works for you let me know!)
* `arm64`: ARMv8 64-bit (RPi 4 64-bit OSes)

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name rtlsdr-airband \
 -p 8000:8000 \
 -e RTLSDRAIRBAND_FREQS=123.9 \
 --device /dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER:/dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER \
fredclausen/rtlsdrairband
```

You should obviously replace `RTLSDRAIRBAND_FREQS` with a frequency you wish to monitor and the /dev/bus/usb path to your RTLSDR dongle.

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
      - RTLSDRAIRBAND_FREQS=123.9
```

## Ports

Port 8000 is exposed in this container.

## Volumes

It is possible to mount `/run/rtlsdir-airband` and provide the container a custom `rtlsdir-airband.conf`. Most users will not want to do this. See [RTLSDR-Advanced Mode](#rtlsdirairband-advanced-mode) for more information.

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
| RTLSDRAIRBAND_RADIO_TYPE | Type of dongle that is providing the radio tuning. Right now, only rtlsdr is usable. If you need something else supported, let me know | No | rtlsdr | 
| RTLSDRAIRBAND_GAIN | Gain setting for the RTLSDR dongle | No | 25 |
| RTLSDRAIRBAND_CORRECTION | Use this if your dongle has a non-zero frequency tuning error, which requires correcting. Put correction value in ppm here. If the dongle tunes too high, this value shall be positive, negative otherwise. | No | 0 |
| RTLSDRAIRBAND_SERIAL | Used to have rtlsdr-airband use the correct dongle if more than one present. Enter the serial of the dongle to be used | No | Unset |
| RTLSDRAIRBAND_MODE | If you are tuning a single frequency, set multichannel. If you are tuning more than one, set as scan | No | multichannel |
| RTLSDRAIRBAND_FREQS| If you are setting `multichannel` for your mode, enter a single frequency. If you are setting mode as `scan`, enter a comma separated list of frequencies you want to scan. Full formatting of the frequencies can be found [here](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuring-channels-for-multichannel-mode) | Yes | Unset |
| RTLSDRAIRBAND_NAME | The name of your stream | No | Tower |
| RTLSDRAIRBAND_GENRE | The genre of your stream | No | ATC |
| RTLSDRAIRBAND_SHOWMETADATA | If not set, the icecast server will receive updated metadata (either frequency or a specific label) of the frequency that is being received, and will show in playback clients. It might be adventageous to disable this because updated metadata will clutter up the icecast server logs. To disable, set to any value. Not applicable to multichannel mode | No | true |
| RTLSDRAIRBAND_LABELS | If RTLSDRAIRBAND_SHOWMETADATA is set to true, you can set this variable to a comma separated list of labels associated with the frequencies you are listening to. If set, the metadata on the icecast server will be updated to show the label associated with the frequency that is currently being received. If not set, the icecast metadata will be updated with the frequency. 

See [the RTSLDR-Airband manual](https://github.com/szpajder/RTLSDR-Airband/wiki/Icecast-metadata-updates-in-scan-mode) for more information, keeping in mind to not include the parenthesis or leading/trailing spaces. 

Additionally, icecast metadata syncing (with or without labels) may not be in sync with the audio. The [the RTSLDR-Airband manual](https://github.com/szpajder/RTLSDR-Airband/wiki/Icecast-metadata-updates-in-scan-mode) explains why.| No | Not set |
| RTLSDRAIRBAND_MOUNTPOINT | The custom part of the stream URL. Streams will be accessable at "serverip:8000/RTLSDRAIRBAND_MOUNTPOINT" | No | GND.mp3 |

### RTLSDIR-Airband Advanced Mode

If you wish to feed multiple icecast servers from the same source RTLSDR dongle, provide the container with more than one RTLSDR dongle, or set up advanced RTLSDR-Airband options that are not configurable via the ENV variables, mount a volume in to the container at

* `/run/rtlsdr-airband`

And set the following ENV variable to any value

* `RTLSDRAIRBAND_CUSTOMCONFIG`

When that value is set, all RTLSDRAIRBAND_* configuration values are ignored and your custom provided `rtlsdr-airband.conf` will be used.

In the mounted volume, provide a file named `rtlsdr-airband.conf` with your configuration. See [RTLSDR-Airband configuration](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuration-essentials) for details on proper formatting of the file.

## Accessing the Web Interface

The web interface for the container can be found at `containerip:8000`

## TODO

* More than one stream from the container
* Disable Icecast if desired and allow connections to a remote Icecast server

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/fredclausen/docker-rtlsdrairband/issues) on the project's GitHub.
