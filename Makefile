ARCHIVE = cache/uxg-setup.tar
SOURCE_IMAGE = localhost/uxg-setup
TARGET_IMAGE = joshuaspence/uxg-setup

SHELL = /bin/bash

.PHONY: build
build: image
	docker load --input $(ARCHIVE)
	$(eval VERSION = $(shell docker image inspect --format '{{ .Config.Labels.version }}' $(SOURCE_IMAGE)))
	docker tag $(SOURCE_IMAGE) $(TARGET_IMAGE):$(VERSION)-original
	docker build --build-arg VERSION=$(VERSION) --tag $(TARGET_IMAGE):$(VERSION) .

.PHONY: image
image: cache/uxg-setup.tar
	mkdir --parents cache
	$(if $(value DEVICE),,$(error DEVICE is undefined))
	ssh -o LogLevel=quiet $(DEVICE) $$'test -f /tmp/conmon || { curl --fail --location --no-progress-meter --output /tmp/conmon https://github.com/boostchicken-dev/udm-utilities/raw/master/podman-update/bin/conmon-2.0.29 && chmod +x /tmp/conmon; }'
	ssh -o LogLevel=quiet $(DEVICE) $$'test -f /tmp/podman || { curl --fail --location --no-progress-meter --output /tmp/podman https://github.com/boostchicken-dev/udm-utilities/raw/master/podman-update/bin/podman-3.3.0 && chmod +x /tmp/podman; }'
	ssh -o LogLevel=quiet $(DEVICE) /tmp/podman --conmon /tmp/conmon save $(SOURCE_IMAGE) | sponge $(ARCHIVE)

.PHONY: push
push:
	docker image push --all-tags $(TARGET_IMAGE)
