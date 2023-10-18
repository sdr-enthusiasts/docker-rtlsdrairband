#!/usr/bin/env sh
#shellcheck shell=sh

set -xe

REPO=fredclausen
IMAGE=rtlsdrairband
PLATFORMS="linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64"

docker context use default
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use cluster

# Build & push latest
docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .

sed "s/NFM_MAKE=\"\"/NFM_MAKE=1/g" < Dockerfile > Dockerfile.NFM

docker buildx build -f Dockerfile.NFM -t "${REPO}/${IMAGE}:latest_nfm" --compress --push --platform "${PLATFORMS}" .
