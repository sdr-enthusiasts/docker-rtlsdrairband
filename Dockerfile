FROM debian:stable-slim

ENV BRANCH_RTLSDR="ed0317e6a58c098874ac58b769cf2e609c18d9a5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    # libusb-1.0-0 + dev - Required for rtl-sdr, libiio (bladeRF/PlutoSDR).
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libmp3lame-dev) && \
    KEPT_PACKAGES+=(libshout3-dev ) && \
    KEPT_PACKAGES+=(libconfig++-dev) && \
    KEPT_PACKAGES+=(libfftw3-dev) && \
    KEPT_PACKAGES+=(libvorbisenc2) &&\
    KEPT_PACKAGES+=(libshout3) && \
    KEPT_PACKAGES+=(libconfig++9v5) && \
    TEMP_PACKAGES+=(gnupg2) && \
    TEMP_PACKAGES+=(file) && \
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(ca-certificates) && \
    TEMP_PACKAGES+=(git) && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
        # rtl-sdr
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    pushd /src/rtl-sdr && \
    #export BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    #git checkout "tags/${BRANCH_RTLSDR}" && \
    git checkout "${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    pushd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    popd && popd && \
    git clone git://github.com/szpajder/RTLSDR-Airband.git /src/rtlsdr-airband && \
    pushd /src/rtlsdr-airband && \
    git checkout master && \
    mkdir -p /src/rtlsdr-airband/build && \
    make PLATFORM=armv8-generic && \
    make install && \
    popd && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* 

COPY rootfs/ /

ENTRYPOINT [ "/init" ]

# Specify location of rrd files as volume
VOLUME [ "/usr/local/etc/" ]
