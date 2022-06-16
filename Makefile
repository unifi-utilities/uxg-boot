SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

CHMOD  := chmod
CURL   := curl --fail --location --no-progress-meter
DOCKER := docker
MKDIR  := @mkdir --parents
SCP    := scp -o LogLevel=quiet
SPONGE := sponge
SSH    := ssh -o LogLevel=quiet
TAR    := tar

export SHELLOPTS := errexit:nounset:pipefail

.DEFAULT: build
.DELETE_ON_ERROR:
.PHONY: build push

build: cache/uxg-setup.tar
	$(DOCKER) image load --input $<

	$(eval VERSION = $(shell $(DOCKER) image inspect --format '{{ .Config.Labels.version }}' $(SOURCE_IMAGE)))
	$(DOCKER) image tag $(SOURCE_IMAGE) $(TARGET_IMAGE):$(VERSION)-original
	$(DOCKER) image build --build-arg VERSION=$(VERSION) --tag $(TARGET_IMAGE):$(VERSION) .

push:
	$(DOCKER) image push --all-tags $(TARGET_IMAGE)

cache/conmon cache/podman: cache/podman.tar.gz
	$(MKDIR) $(@D)
	$(TAR) --extract --file $< --to-stdout --no-anchored $(@F) > $@
	$(CHMOD) +x $@

# TODO: Update to Podman 4.
cache/podman.tar.gz:
	$(MKDIR) $(@D)
	$(CURL) --output $@ https://github.com/mgoltzsche/podman-static/releases/download/v3.4.2/podman-linux-arm64.tar.gz

# TODO: Fix errors/warnings.
# TODO: Use `>` instead of `|`.
cache/uxg-setup.tar: cache/conmon cache/podman
	$(SCP) $^ $(DEVICE):/tmp
	$(SSH) $(DEVICE) /tmp/podman --conmon /tmp/conmon save $(SOURCE_IMAGE) | $(SPONGE) $@
