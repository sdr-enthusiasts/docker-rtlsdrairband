#!/usr/bin/env sh
#shellcheck shell=sh

set -xe

REPO=fredclausen
IMAGE=rtlsdrairband
PLATFORMS="linux/arm/v6"

docker context use default
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use cluster

# Build & push latest
docker buildx build -t "${REPO}/${IMAGE}:test" --compress --push --platform "${PLATFORMS}" .