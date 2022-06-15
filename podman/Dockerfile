ARG GOLANG_VERSION=latest
FROM golang:${GOLANG_VERSION}

ARG PODMAN_VERSION=3.4.4

WORKDIR /workspace
RUN git -c advice.detachedHead=false clone --branch v${PODMAN_VERSION} https://github.com/containers/podman.git .
RUN GOARCH=amd64 make bin/podman.cross.linux.arm64
