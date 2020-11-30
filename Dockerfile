FROM debian:stable-slim

ENV BRANCH_RTLSDR="ed0317e6a58c098874ac58b769cf2e609c18d9a5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    ## Both services
    PORT="8000" \
    ## Icecast
    ICECAST_DISABLE="" \
    ICECAST_CUSTOMCONFIG="" \
    ICECAST_ADMIN_PASSWORD="rtlsdrairband" \
    ICECAST_ADMIN_USERNAME="admin" \
    ICECAST_ADMIN_EMAIL="test@test.com" \
    ICECAST_LOCATION="earth" \
    ICECAST_HOSTNAME="localhost" \
    ICECAST_MAX_CLIENTS="100" \
    ICECAST_MAX_SOURCES="4" \
    ## RTLSDR AirBand
    RTLSDRAIRBAND_CUSTOMCONFIG="" \
    RTLSDRAIRBAND_RADIO_TYPE="rtlsdr" \
    RTLSDRAIRBAND_GAIN=40 \
    RTLSDRAIRBAND_CORRECTION="" \
    RTLSDRAIRBAND_MODE="multichannel" \
    RTLSDRAIRBAND_FREQS="" \
    RTLSDRAIRBAND_SERIAL=""; \
    RTLSDRAIRBAND_MOUNTPOINT="GND.mp3" \
    RTLSDRAIRBAND_NAME="Tower" \
    RTLSDRAIRBAND_GENRE="ATC" \
    RTLSDRAIRBAND_DESCRIPTION="Air traffic feed" \
    RTLSDRAIRBAND_LABELS="" \
    RTLSDRAIRBAND_SHOWMETADATA="" \
    SQUELCH=""


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # logging
    KEPT_PACKAGES+=(gawk) && \
    # required for S6 overlay
    TEMP_PACKAGES+=(gnupg2) && \
    TEMP_PACKAGES+=(file) && \
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(ca-certificates) && \
    # libusb-1.0-0 + dev - Required for rtl-sdr, libiio (bladeRF/PlutoSDR).
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    # Required to run RTLSDR-Arband
    KEPT_PACKAGES+=(libmp3lame-dev) && \
    KEPT_PACKAGES+=(libshout3-dev ) && \
    KEPT_PACKAGES+=(libconfig++-dev) && \
    KEPT_PACKAGES+=(libfftw3-dev) && \
    KEPT_PACKAGES+=(libvorbisenc2) &&\
    KEPT_PACKAGES+=(libshout3) && \
    KEPT_PACKAGES+=(libconfig++9v5) && \
    # packages for icecast
    KEPT_PACKAGES+=(libxml2) && \
    TEMP_PACKAGES+=(libxml2-dev) && \
    KEPT_PACKAGES+=(libxslt1.1) && \
    TEMP_PACKAGES+=(libxslt1-dev) && \
    KEPT_PACKAGES+=(mime-support) && \
    # install first round of packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    # icecast install
    sh -c "echo deb-src http://download.opensuse.org/repositories/multimedia:/xiph/Debian_9.0/ ./ >>/etc/apt/sources.list.d/icecast.list" && \
    wget -qO - http://icecast.org/multimedia-obs.key | apt-key add - && \
    KEPT_PACKAGES+=(icecast2) && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    mkdir -p /etc/icecast2/logs && \
    chown -R icecast2 /etc/icecast2; \
    # rtl-sdr
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    pushd /src/rtl-sdr && \
    git checkout "${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    pushd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    popd && popd && \
    # install RTLSDR-Airband
    curl -s https://raw.githubusercontent.com/fredclausen/docker-rtlsdrairband/main/Install%20Scripts/rtlsdr-airband-deploy.sh | sh && \
    # install S6 Overlay
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # Clean up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* 

COPY rootfs/ /

ENTRYPOINT [ "/init" ]
