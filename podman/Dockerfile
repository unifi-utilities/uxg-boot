ARG GOLANG_VERSION=latest
FROM golang:${GOLANG_VERSION}

RUN \
	dpkg --add-architecture arm64 && \
	apt-get update && \
	apt-get install --no-install-recommends --yes gcc-aarch64-linux-gnu libc6-dev:arm64 libseccomp-dev:arm64 && \
	rm --recursive --force /var/lib/apt/lists/*

ARG PODMAN_VERSION=3.3.0
ENV CC=aarch64-linux-gnu-gcc
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig

WORKDIR /workspace
RUN git -c advice.detachedHead=false clone --branch v${PODMAN_VERSION} https://github.com/containers/podman.git .
RUN \
  BUILDTAGS='containers_image_openpgp exclude_graphdriver_btrfs exclude_graphdriver_devicemapper exclude_graphdriver_overlay' \
  GOARCH=arm64 \
  make bin/podman
