FROM debian:bullseye-20211220-slim

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
    SQUELCH="" \
    LOG_SCAN_ACTIVITY="" \
    FFT_SIZE="2048" \
    SAMPLE_RATE="2.56"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs/ /

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
    # packages for icecast
    KEPT_PACKAGES+=(libxml2) && \
    TEMP_PACKAGES+=(libxml2-dev) && \
    KEPT_PACKAGES+=(libxslt1.1) && \
    TEMP_PACKAGES+=(libxslt1-dev) && \
    KEPT_PACKAGES+=(mime-support) && \
    # Dependencies for bladeRF
    KEPT_PACKAGES+=(libncurses5) && \
    TEMP_PACKAGES+=(libncurses5-dev) && \
    KEPT_PACKAGES+=(libtecla1) && \
    TEMP_PACKAGES+=(libtecla-dev) && \
    KEPT_PACKAGES+=(libedit2) && \
    TEMP_PACKAGES+=(libedit-dev) && \
    # Dependencies for hackrf
    KEPT_PACKAGES+=(libfftw3-3) && \
    TEMP_PACKAGES+=(libfftw3-dev) && \
    # Dependencies for PlutoSDR
    KEPT_PACKAGES+=(libiio0) && \
    TEMP_PACKAGES+=(libiio-dev) && \
    KEPT_PACKAGES+=(libad9361-0) && \
    TEMP_PACKAGES+=(libad9361-dev) && \
    # Dependencies for SoapyRemote
    KEPT_PACKAGES+=(avahi-daemon) && \
    TEMP_PACKAGES+=(libavahi-client-dev) && \
    KEPT_PACKAGES+=(libavahi-client3) && \
    TEMP_PACKAGES+=(libavahi-common-dev) && \
    KEPT_PACKAGES+=(libavahi-common3) && \
    KEPT_PACKAGES+=(libavahi-common-data) && \
    TEMP_PACKAGES+=(libavahi-core-dev) && \
    KEPT_PACKAGES+=(libavahi-core7) && \
    TEMP_PACKAGES+=(libdbus-1-dev) && \
    KEPT_PACKAGES+=(libdbus-1-3) && \
    # Required for healthchecks
    KEPT_PACKAGES+=(net-tools) && \
    # install first round of packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ${KEPT_PACKAGES[@]} \
      ${TEMP_PACKAGES[@]} \
      && \
    # icecast install
    sh -c "echo deb-src http://download.opensuse.org/repositories/multimedia:/xiph/Debian_9.0/ ./ >>/etc/apt/sources.list.d/icecast.list" && \
    curl -s --location http://icecast.org/multimedia-obs.key | apt-key add - && \
    KEPT_PACKAGES+=(icecast2) && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ${KEPT_PACKAGES[@]} \
      ${TEMP_PACKAGES[@]} \
      && \
    mkdir -p /etc/icecast2/logs && \
    chown -R icecast2 /etc/icecast2 && \
    # Deploy rtl-sdr
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
    # Deploy bladeRF
    git clone https://github.com/Nuand/bladeRF.git /src/bladeRF && \
    pushd /src/bladeRF && \
    BRANCH_BLADERF=$(git tag --sort="creatordate" | grep -P '^[\d\.]+$' | tail -1) && \
    git checkout "$BRANCH_BLADERF" && \
    mkdir -p /src/bladeRF/build && \
    pushd /src/bladeRF/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_UDEV_RULES=ON ../ && \
    make all && \
    make install && \
    popd && popd && \
    # Download bladeRF FPGA Images
    BLADERF_RBF_PATH="/usr/share/Nuand/bladeRF" && \
    mkdir -p "$BLADERF_RBF_PATH" && \
    curl -o "$BLADERF_RBF_PATH/hostedxA4.rbf" https://www.nuand.com/fpga/hostedxA4-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedxA9.rbf" https://www.nuand.com/fpga/hostedxA9-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedx40.rbf" https://www.nuand.com/fpga/hostedx40-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedx115.rbf" https://www.nuand.com/fpga/hostedx115-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbxA4.rbf" https://www.nuand.com/fpga/adsbxA4.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbxA9.rbf" https://www.nuand.com/fpga/adsbxA9.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbx40.rbf" https://www.nuand.com/fpga/adsbx40.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbx115.rbf" https://www.nuand.com/fpga/adsbx115.rbf && \
    # Deploy hackrf
    git clone https://github.com/mossmann/hackrf.git /src/hackrf && \
    pushd /src/hackrf && \
    BRANCH_HACKRF=$(git tag --sort="creatordate" | grep -P '^v[\d\.]+$' | tail -1) && \
    git checkout "$BRANCH_HACKRF" && \
    mkdir -p /src/hackrf/host/build && \
    pushd /src/hackrf/host/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy airspy
    git clone https://github.com/airspy/airspyone_host.git /src/airspyone_host && \
    pushd /src/airspyone_host && \
    BRANCH_AIRSPYONE_HOST=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_AIRSPYONE_HOST" && \
    mkdir -p /src/airspyone_host/build && \
    pushd /src/airspyone_host/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy airspyhf
    git clone https://github.com/airspy/airspyhf.git /src/airspyhf && \
    pushd /src/airspyhf && \
    BRANCH_AIRSPYHF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_AIRSPYHF" && \
    mkdir -p /src/airspyhf/build && \
    pushd /src/airspyhf/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapySDR
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    BRANCH_SOAPYSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYSDR" && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy LimeSuite
    git clone https://github.com/myriadrf/LimeSuite.git /src/LimeSuite && \
    pushd /src/LimeSuite && \
    # The upstream repo has not tagged a bunch of updates
    # For some reason the latest tagged version (ADPD-v17.06.0 as of 15 Jan 22) has a bunch of build artifacts
    # from his home computer. I can't find a commit where those were deleted so I suspect it was kind of dev branch?
    # Use the current "latest" master branch for now.
    # BRANCH_LIMESUITE=$(git tag --sort="creatordate" | tail -1) && \
    # git checkout "$BRANCH_LIMESUITE" && \
    mkdir -p /src/LimeSuite/build && \
    pushd /src/LimeSuite/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRemote
    git clone https://github.com/pothosware/SoapyRemote.git /src/SoapyRemote && \
    pushd /src/SoapyRemote && \
    BRANCH_SOAPYREMOTE=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYREMOTE" && \
    mkdir -p /src/SoapyRemote/build && \
    pushd /src/SoapyRemote/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRTLSDR
    git clone https://github.com/pothosware/SoapyRTLSDR.git /src/SoapyRTLSDR && \
    pushd /src/SoapyRTLSDR && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYRTLSDR" && \
    mkdir -p /src/SoapyRTLSDR/build && \
    pushd /src/SoapyRTLSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyBladeRF
    git clone https://github.com/pothosware/SoapyBladeRF.git /src/SoapyBladeRF && \
    pushd /src/SoapyBladeRF && \
    BRANCH_SOAPYBLADERF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYBLADERF" && \
    mkdir -p /src/SoapyBladeRF/build && \
    pushd /src/SoapyBladeRF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyHackRF
    git clone https://github.com/pothosware/SoapyHackRF.git /src/SoapyHackRF && \
    pushd /src/SoapyHackRF && \
    BRANCH_SOAPYHACKRF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYHACKRF" && \
    mkdir -p /src/SoapyHackRF/build && \
    pushd /src/SoapyHackRF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyPlutoSDR
    git clone https://github.com/pothosware/SoapyPlutoSDR.git /src/SoapyPlutoSDR && \
    pushd /src/SoapyPlutoSDR && \
    BRANCH_SOAPYPLUTOSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYPLUTOSDR" && \
    mkdir -p /src/SoapyPlutoSDR/build && \
    pushd /src/SoapyPlutoSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deplot SoapyAirspy
    git clone https://github.com/pothosware/SoapyAirspy.git /src/SoapyAirspy && \
    pushd /src/SoapyAirspy && \
    BRANCH_SOAPYAIRSPY=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYAIRSPY" && \
    mkdir -p /src/SoapyAirspy/build && \
    pushd /src/SoapyAirspy/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyAirspyHF
    git clone https://github.com/pothosware/SoapyAirspyHF.git /src/SoapyAirspyHF && \
    pushd /src/SoapyAirspyHF && \
    BRANCH_SOAPYAIRSPYHF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYAIRSPYHF" && \
    mkdir -p /src/SoapyAirspyHF/build && \
    pushd /src/SoapyAirspyHF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyMultiSDR
    git clone https://github.com/pothosware/SoapyMultiSDR.git /src/SoapyMultiSDR && \
    pushd /src/SoapyMultiSDR && \
    mkdir -p /src/SoapyMultiSDR/build && \
    pushd /src/SoapyMultiSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # install S6 Overlay
    curl -o /tmp/deploy-s6-overlay.sh https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh && \
    bash -x /tmp/deploy-s6-overlay.sh && \
    # Deploy healthchecks framework
    git clone \
      --depth=1 \
      "https://github.com/mikenye/docker-healthchecks-framework.git" \
      /opt/healthchecks-framework \
      && \
    rm -rf \
      /opt/healthchecks-framework/.git* \
      /opt/healthchecks-framework/*.md \
      /opt/healthchecks-framework/tests \
      && \
    # Get rtl_airband source (compiled on first run via /etc/cont-init.d/01-build-rtl_airband)
    git clone https://github.com/szpajder/RTLSDR-Airband.git /opt/rtlsdr-airband && \
    pushd /opt/rtlsdr-airband && \
    BRANCH_RTL_AIRBAND=$(git tag | tail -1) && \
    git checkout "$BRANCH_RTL_AIRBAND" && \
    echo "$BRANCH_RTL_AIRBAND" > /CONTAINER_VERSION && \
    popd && \
    # Clean up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    # Install packages required for first-run build of rtl_airband
    # This is done after clean-up to prevent accidental package removal
    unset KEPT_PACKAGES && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(file) && \
    KEPT_PACKAGES+=(g++) && \
    KEPT_PACKAGES+=(libconfig++-dev) && \
    KEPT_PACKAGES+=(libfftw3-dev) && \
    KEPT_PACKAGES+=(libmp3lame-dev) && \
    KEPT_PACKAGES+=(libogg-dev) && \
    KEPT_PACKAGES+=(libshout3-dev) && \
    KEPT_PACKAGES+=(libvorbis-dev) && \
    KEPT_PACKAGES+=(make) && \
    KEPT_PACKAGES+=(cmake) && \
    apt-get install -y --no-install-recommends \
      ${KEPT_PACKAGES[@]} \
      && \
    # Clean up
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=300s --interval=300s CMD /scripts/healthcheck.sh
