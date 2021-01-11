# docker-rtlsdrairband

Docker container to run [RTLSDR-Airband](https://github.com/szpajder/RTLSDR-Airband) alongside [Icecast](https://icecast.org). Builds and runs on `arm64`. A container is provided for, but not tested, `amd64` and `arm32v7` (see below).

This container runs an Icecast audio server that RTLSDR-Airband can connect to so that you can use an RTLSDR dongle to listen to Air Traffic Control VHF radio communications, as well some some additional kinds of NFM modulated transmissions (see [NFM](#nfm)) via a web browser or audio playback program.

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* `latest_nfm` (`master` branch, `Dockerfile.NFM`. See [NFM](#nfm) below)
* Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64 (Builds but is untested. If it works for you let me know!)
* `arm32v7`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3) (Builds but is untested. If it works for you let me know!)
* `arm64`: ARMv8 64-bit (RPi 3 and 4 64-bit OSes)

## Thanks

Thanks to [mikenye](https://github.com/mikenye) for his excellent ADSB docker containers from which I shamelessly copied a lot of the ideas for setting up the docker container, as well as his excellent advice and help in getting this thing working.

## Required Hardware

You will need at least one RTLSDR dongle, and if multiple dongles are present on the system the dongle you are using needs to have the serial number set and passed in to the container (see ENV configuration below). [Kerberos SDR](https://othernet.is/products/kerberossdr-4x-coherent-rtl-sdr) RTLSDR devices will also work with this container.

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name rtlsdr-airband \
 -p 8000:8000 \
 -e RTLSDRAIRBAND_FREQS=123.9 \
 --device /dev/bus/usb:/dev/bus/usb \
fredclausen/rtlsdrairband
```

You should obviously replace `RTLSDRAIRBAND_FREQS` with a frequency you wish to monitor.

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
      - /dev/bus/usb:/dev/bus/usb
    ports:
      - 8000:8000
    environment:
      - RTLSDRAIRBAND_FREQS=123.9
```

## Ports

Port 8000 is exposed by default in this container. If you want to use another port, set the following ENV variable

* PORT

To the port value you want. In the container startup command, ensure the value you set in the `PORT` ENV variable is used in place of 8000. For example, using the above docker compose with `PORT` set to 9000, the port line should look like this

```yaml
    ports:
      - 9000:9000
    environment:
      - RTLSDRAIRBAND_FREQS=123.9
      - PORT=9000
```

## Volumes

It is possible to mount `/run/rtlsdir-airband` and provide the container a custom `rtlsdir-airband.conf` or `icecast.xml`. Most users will not want to do this. See [RTLSDR-Advanced Mode](#rtlsdir-airband-advanced-mode) and/or [Icecast Advanced Mode](#icecast-advanced-mode) for more information.

## Environment variables

There are quite a few configuration options this container can accept.

### Icecast

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| `ICECAST_DISABLE` | Set to any value to disable icecast server. You will want to do this if you are streaming to an external icecast server such as liveatc or another server you have set up. If this value is set, you should proceed to [RTLSDR-Advanced Mode](#rtlsdir-airband-advanced-mode) as the default RTLSDR-Airband configuration will not connect to external icecast server | No | `Unset` |
| `ICECAST_ADMIN_USERNAME` | The username used to log in to the admin interface | No | `admin` |
| `ICECAST_ADMIN_PASSWORD` | The password used to log in to the admin interface. | No | `rtlsdrairband` |
| `ICECAST_ADMIN_EMAIL` | Admin email shown in the web interface. | No | `test@test.com` |
| `ICECAST_LOCATION` | Location of server | No | `earth` |
| `ICECAST_HOSTNAME` | The hostname or IP used to reach the icecast server. Used to show correct URLs for the streams on the web interface | No | `localhost` |
| `ICECAST_MAX_CLIENTS` | Maximum listeners | No | `100` |
| `ICECAST_MAX_SOURCES` | Maximum number of clients that can provide a stream to the server | No | `4` |

### RTLSDR-Airband

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| `RTLSDRAIRBAND_RADIO_TYPE` | Type of dongle that is providing the radio tuning. Right now, only rtlsdr is usable. If you need something else supported, let me know | No | `rtlsdr` |
| `RTLSDRAIRBAND_GAIN` | Gain setting for the RTLSDR dongle | No | `25` |
| `RTLSDRAIRBAND_CORRECTION` | Use this if your dongle has a non-zero frequency tuning error, which requires correcting. Put correction value in ppm here. If the dongle tunes too high, this value shall be positive, negative otherwise. | No | `0` |
| `RTLSDRAIRBAND_SERIAL` | Used to have rtlsdr-airband use the correct dongle if more than one present. Enter the serial of the dongle to be used | No | `Unset` |
| `RTLSDRAIRBAND_MODE` | If you are tuning a single frequency, set multichannel. If you are tuning more than one, set as scan | No | `multichannel` |
| `RTLSDRAIRBAND_FREQS`| If you are setting `multichannel` for your mode, enter a single frequency. If you are setting mode as `scan`, enter a comma separated list of frequencies you want to scan. Full formatting of the frequencies can be found [here](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuring-channels-for-multichannel-mode) | **Yes** | `Unset` |
| `RTLSDRAIRBAND_NAME` | The name of your stream | No | `Tower` |
| `RTLSDRAIRBAND_GENRE` | The genre of your stream | No | `ATC` |
| `RTLSDRAIRBAND_DESCRIPTION` | A description of your stream | No | `Air traffic feed` |
| `RTLSDRAIRBAND_SHOWMETADATA` | If not set, the icecast server will receive updated metadata (either frequency or a specific label) of the frequency that is being received, and will show in playback clients. It might be adventageous to disable this because updated metadata will clutter up the icecast server logs. To disable, set to any value. Not applicable to multichannel mode | No | `true` |
| `RTLSDRAIRBAND_LABELS` | If `RTLSDRAIRBAND_SHOWMETADATA` is set to true, you can set this variable to a comma separated list of labels associated with the frequencies you are listening to. If set, the metadata on the icecast server will be updated to show the label associated with the frequency that is currently being received. If not set, the icecast metadata will be updated with the frequency. * See notes below for more information.| No | `unset` |
| `RTLSDRAIRBAND_MOUNTPOINT` | The custom part of the stream URL. Streams will be accessable at `serverip:PORT/RTLSDRAIRBAND_MOUNTPOINT` | `No` | `GND.mp3` |
| `LOG_SCAN_ACTIVITY` | rtlsdr-airband can output what frequencies it has received traffic on. Set this to any non-blank value to enable | `No` | `Unset` |
| `FFT_SIZE` | This value controls the general audio quality. A larger value means increased CPU usage. Accepted values are powers of two in the range of 256-8192, inclusive. | No | `2048` |
| `SAMPLE_RATE` | Set the sample rate of the audio stream. See [this](https://github.com/szpajder/RTLSDR-Airband/wiki/Tweaking-sampling-rate-and-FFT-size) for more information. Also see notes below. | No | `2.56` |

* See [the RTSLDR-Airband manual](https://github.com/szpajder/RTLSDR-Airband/wiki/Icecast-metadata-updates-in-scan-mode) for more information, keeping in mind to not include the parenthesis or leading/trailing spaces.

* Additionally, icecast metadata syncing (with or without labels) may not be in sync with the audio. The [RTSLDR-Airband manual](https://github.com/szpajder/RTLSDR-Airband/wiki/Icecast-metadata-updates-in-scan-mode) explains why.

* Not all RTLSDR dongles will support sample rates above 2.56. If you see a dramatic reduction in reception after increasing sample rate above 2.56, reduce it back down.

### Testing

If you want to test and make sure the stream is working, please ensure

* `RTLSDRAIRBAND_MODE`

Is either unset or set to multichannel

And then add this to your enviornment variables

* `SQUELCH`

And set it any non-blank value. That will turn off auto-squelch and you will hear static when you open the stream.

### RTLSDIR-Airband Advanced Mode

If you wish to feed multiple icecast servers from the same source RTLSDR dongle, provide the container with more than one RTLSDR dongle, use SoapySDR to access non-RTLSDR dongles, or set up advanced RTLSDR-Airband options that are not configurable via the ENV variables, mount a volume in to the container at:

* `/run/rtlsdr-airband`

And set the following ENV variable to any value

* `RTLSDRAIRBAND_CUSTOMCONFIG`

When that value is set, all `RTLSDRAIRBAND_*` configuration values are ignored and your custom provided `rtl_airband.conf` will be used.

In the mounted volume, provide a file named `rtl_airband.conf` with your configuration. See [RTLSDR-Airband configuration](https://github.com/szpajder/RTLSDR-Airband/wiki/Configuration-essentials) for details on proper formatting of the file.

SoapySDR support for the following hardware is provided:

* HackRF
* AirSpy & AirSpy HF
* LimeSDR
* BladeRF
* PlutoSDR
* SoapyRemote

### Icecast Advanced Mode

Icecast has many advanced options that can be set beyond the provided ENV variables. If you wish to do so, mount a volume at

* `/run/rtlsdr-airband`

And set the following ENV variable to any value

* `ICECAST_CUSTOMCONFIG`

When that value is set, all ICECAST_* configuration values are ignored and your custom provided `icecast.xml` will be used.

In the mounted volume, provide a file named `icecast.xml` with your configuration. See the [icecast documentation](https://icecast.org/docs/) for details on proper formatting of the file.

## NFM

The primary purpose of this container is to monitor VHF airband communications. However, the underlying software is not limited to strictly VHF communications and AM modulation. Using the `fredclausen/rtlsdrairband:latest_nfm` image you have the ability to enable NFM modulation and monitor additional radio communications (as I understand it, things like Railroad communications). This is not enabled in the `latest` tag by default because of the additional CPU overhead required (should be marginal, but not negligible if your hardware is constrained), but if you desire the functionality, please use the `latest_nfm` tag.

## Accessing the Web Interface

The web interface for the container can be found at `containerip:8000` or `containerip:port` if `PORT` ENV variable is set.

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/fredclausen/docker-rtlsdrairband/issues) on the project's GitHub.
