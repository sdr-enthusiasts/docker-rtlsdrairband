#!/bin/bash

APPNAME="rtlsdr-airband"

echo "[$APPNAME] Determining architecture of target image"

# Make sure `file` (libmagic) is available
FILEBINARY=$(which file)
if [ -z "$FILEBINARY" ]; then
  echo "[$APPNAME] ERROR: 'file' (libmagic) not available, cannot detect architecture!"
  exit 1
fi

FILEOUTPUT=$("${FILEBINARY}" -L "${FILEBINARY}")

# 32-bit x86
# Example output:
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386.so.1, stripped
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=d48e1d621e9b833b5d33ede3b4673535df181fe0, stripped  
if echo "${FILEOUTPUT}" | grep "Intel 80386" > /dev/null; then
  ARCH="x86"
  echo "[$APPNAME] Building rtlsdr-airband for x86"
  PLATFORM=x86
fi

# x86-64
# Example output:
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=6b0b86f64e36f977d088b3e7046f70a586dd60e7, stripped
if echo "${FILEOUTPUT}" | grep "x86-64" > /dev/null; then
  ARCH="amd64"
  echo "[$APPNAME] Building rtlsdr-airband for x86"
  PLATFORM=x86
fi

# armel
# /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=f57b617d0d6cd9d483dcf847b03614809e5cd8a9, stripped
if echo "${FILEOUTPUT}" | grep "ARM" > /dev/null; then

  # ARCH="arm"

  # armhf
  # Example outputs:
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-armhf.so.1, stripped  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  if echo "${FILEOUTPUT}" | grep "armhf" > /dev/null; then
    ARCH="armhf"
    echo "[$APPNAME] Building rtlsdr-airband for arm32v7"
    PLATFORM=armv7-generic
  fi

  # arm64
  # Example output:
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, BuildID[sha1]=a8d6092fd49d8ec9e367ac9d451b3f55c7ae7a78, stripped
  if echo "${FILEOUTPUT}" | grep "aarch64" > /dev/null; then
    ARCH="aarch64"
    echo "[$APPNAME] Building rtlsdr-airband for arm64"
    PLATFORM=armv8-generic
  fi

fi

# If we don't have an architecture at this point, there's been a problem and we can't continue
if [ -z "${ARCH}" ]; then
  echo "[$APPNAME] ERROR: Unable to determine architecture or unsupported architecture!"
  exit 1
fi

echo "[$APPNAME] Arch is $ARCH"
echo "[$APPNAME] Using make options PLATFORM=$PLATFORM WITH_SOAPYSDR=1 NFM_MAKE=$NFM_MAKE"
echo "[$APPNAME] Writing build script: /scripts/build_rtl_airband.sh"

# Write build script (to be executed by /etc/cont-init.d/01-build-rtl_airband)
{
  echo "#!/usr/bin/env bash"
  echo "pushd /opt/rtlsdr-airband > /dev/null || exit 1"
  echo "make PLATFORM=\"$PLATFORM\" WITH_SOAPYSDR=1 NFM_MAKE=\"$NFM_MAKE\""
  echo "make install"
  echo "popd > /dev/null"
} > /scripts/build_rtl_airband.sh

# Make script executable
chmod a+x /scripts/build_rtl_airband.sh
