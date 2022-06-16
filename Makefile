SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

CHMOD  := chmod
CURL   := curl --fail --location --no-progress-meter
DOCKER := docker
JQ     := jq --raw-output
MKDIR  := @mkdir --parents
SCP    := scp -o LogLevel=quiet
SKOPEO := skopeo
SSH    := ssh -o LogLevel=quiet
TAR    := tar

.DEFAULT: build
.DELETE_ON_ERROR:
.PHONY: build push

build: cache/uxg-setup.tar
	$(DOCKER) image load --input $<
	$(eval SOURCE_IMAGE := $(shell $(SKOPEO) inspect --raw docker-archive:$< | $(JQ) .config.digest))
	$(eval VERSION = $(shell $(SKOPEO) inspect --config --raw docker-archive:$< | $(JQ) .config.Labels.version))
	$(DOCKER) image tag $(SOURCE_IMAGE) $(TARGET_IMAGE):$(VERSION)-original
	$(DOCKER) image build --build-arg VERSION=$(VERSION) --tag $(TARGET_IMAGE):$(VERSION) .

push:
	$(DOCKER) image push --all-tags $(TARGET_IMAGE)

cache/conmon: cache/podman.tar.gz
	$(MKDIR) $(@D)
	$(TAR) --extract --file $< --directory $(@D) --strip-components=5 podman-linux-arm64/usr/local/lib/podman/conmon

cache/podman: cache/podman.tar.gz
	$(MKDIR) $(@D)
	$(TAR) --extract --file $< --directory $(@D) --strip-components=4 podman-linux-arm64/usr/local/bin/podman

# TODO: Update to Podman 4.
cache/podman.tar.gz:
	$(MKDIR) $(@D)
	$(CURL) --output $@ https://github.com/mgoltzsche/podman-static/releases/download/v3.4.2/podman-linux-arm64.tar.gz

# TODO: Fix errors/warnings.
cache/uxg-setup.tar: cache/conmon cache/podman
	$(SCP) $^ $(DEVICE):/tmp
	$(SSH) $(DEVICE) /tmp/podman --conmon /tmp/conmon save $(SOURCE_IMAGE) > $@
