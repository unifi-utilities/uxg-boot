SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

CHMOD  := chmod
CURL   := curl --fail --location --no-progress-meter
DOCKER := docker
MKDIR  := mkdir --parents
SCP    := scp -o LogLevel=quiet
SSH    := ssh -o LogLevel=quiet
TAR    := tar

export SHELLOPTS := pipefail

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
	@$(MKDIR) $(@D)
	$(SCP) $^ $(DEVICE):/tmp
	$(SSH) $(DEVICE) /tmp/podman --conmon /tmp/conmon save $(SOURCE_IMAGE) | sponge $@

# TODO: Update to Podman 4
cache/podman.tar.gz:
	@$(MKDIR) $(@D)
	$(CURL) --output $@ https://github.com/mgoltzsche/podman-static/releases/download/v3.4.2/podman-linux-arm64.tar.gz

cache/conmon cache/podman: cache/podman.tar.gz
	@$(MKDIR) $(@D)
	$(TAR) --extract --file $< --to-stdout --no-anchored $(@F) > $@
	$(CHMOD) +x $@
