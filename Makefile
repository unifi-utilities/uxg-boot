SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

CURL      := curl --location --show-error --silent
DOCKER    := docker
SCP       := scp -o LogLevel=quiet
SHELL     := /bin/bash
SHELLOPTS := pipefail
SSH       := ssh -o LogLevel=quiet
TAR       := tar

export SHELLOPTS

.DELETE_ON_ERROR:

.PHONY: build
build: cache/uxg-setup.tar
	$(DOCKER) load --input cache/uxg-setup.tar
	$(eval VERSION = $(shell $(DOCKER) image inspect --format '{{ .Config.Labels.version }}' $(SOURCE_IMAGE)))
	$(DOCKER) tag $(SOURCE_IMAGE) $(TARGET_IMAGE):$(VERSION)-original
	$(DOCKER) build --build-arg VERSION=$(VERSION) --tag $(TARGET_IMAGE):$(VERSION) .

.PHONY: push
push:
	$(DOCKER) image push --all-tags $(TARGET_IMAGE)

cache/uxg-setup.tar: cache/podman cache/conmon
	@mkdir --parents $(@D)

	$(SCP) $^ $(DEVICE):/tmp
	$(SSH) $(DEVICE) /tmp/podman --conmon /tmp/conmon save $(SOURCE_IMAGE) | sponge $@

# TODO: Update to Podman 4
cache/podman.tar.gz:
	$(CURL) --output $@ https://github.com/mgoltzsche/podman-static/releases/download/v3.4.2/podman-linux-arm64.tar.gz

cache/conmon cache/podman: cache/podman.tar.gz
	$(TAR) --extract --file $< --to-stdout --no-anchored $(@F) > $@
	chmod +x $@
