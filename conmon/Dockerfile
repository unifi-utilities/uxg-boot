ARG GOLANG_VERSION=latest
FROM golang:${GOLANG_VERSION}

RUN \
	dpkg --add-architecture arm64 && \
	apt-get update && \
	apt-get install --no-install-recommends --yes gcc-aarch64-linux-gnu libglib2.0-dev:arm64 libseccomp-dev:arm64 && \
	rm --recursive --force /var/lib/apt/lists/*

ARG CONMON_VERSION=2.1.0
ENV CC=aarch64-linux-gnu-gcc
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig

WORKDIR /workspace
RUN git -c advice.detachedHead=false clone --branch v${CONMON_VERSION} https://github.com/containers/conmon.git .
RUN make bin/conmon
