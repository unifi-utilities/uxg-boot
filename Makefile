SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

DOCKER    := docker
SCP       := scp -o LogLevel=quiet
SHELL     := /bin/bash
SHELLOPTS := pipefail
SSH       := ssh -o LogLevel=quiet

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

cache/podman: podman/Dockerfile
	$(DOCKER) build --no-cache --file $< --tag podman-builder $(<D)
	$(DOCKER) run --rm --volume $$(pwd)/cache:/build --entrypoint cp podman-builder /workspace/bin/podman.cross.linux.arm64 /build/podman

cache/conmon: conmon/Dockerfile
	$(DOCKER) build --no-cache --file $< --tag conmon-builder $(<D)
	$(DOCKER) run --rm --volume $$(pwd)/cache:/build --entrypoint cp conmon-builder /workspace/bin/conmon /build/conmon
