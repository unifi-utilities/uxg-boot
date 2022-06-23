AWK    := awk
CHOWN  := sudo chown --recursive $(USER):$(USER)
CURL   := curl --fail --location --no-progress-meter
JQ     := jq --raw-output --exit-status
PODMAN := podman
MKDIR  := @mkdir --parents

SOURCE_IMAGE := uxg-setup
TARGET_IMAGE := docker.io/joshuaspence/uxg-setup

MAKEFLAGS += --no-print-directory
MAKEFLAGS += --warn-undefined-variables

.DELETE_ON_ERROR:
.PHONY: build push
.SECONDARY:

ifdef FIRMWARE_VERSION
build: cache/uxgpro-$(FIRMWARE_VERSION)/image.tar
	$(PODMAN) image load --input cache/uxgpro-$(FIRMWARE_VERSION)/image.tar
	$(PODMAN) image build --build-arg BUILD_FROM=$(SOURCE_IMAGE) --label source_firmware=$(FIRMWARE_VERSION) --tag $(TARGET_IMAGE):$$($(PODMAN) image inspect --format '{{ .Config.Labels.version }}' $(SOURCE_IMAGE)) .

ifdef DOCKER_PUSH
	$(PODMAN) image push $(TARGET_IMAGE):$$($(PODMAN) image inspect --format '{{ .Config.Labels.version }}' $(SOURCE_IMAGE))
endif
else
build:
	$(MAKE) FIRMWARE_VERSION=$$($(CURL) --header 'X-Requested-With: XMLHttpRequest' https://www.ui.com/download/?product=uxg-pro | $(JQ) '.downloads | map(select(.category__slug == "firmware")) | max_by(.version) | .version')
endif

cache/uxgpro-%/firmware.bin: cache/uxgpro-%/firmware.json
	$(MKDIR) $(@D)
	$(CURL) --output $@ $$($(JQ) .file_path $<)

cache/uxgpro-%/firmware.json:
	$(MKDIR) $(@D)
	$(CURL) --header 'X-Requested-With: XMLHttpRequest' https://www.ui.com/download/?product=uxg-pro | $(JQ) --arg version $* '.downloads[] | select(.category__slug == "firmware" and .version == $$version)' > $@

cache/uxgpro-%/fs: cache/uxgpro-%/firmware.bin
	firmware-mod-kit/extract-firmware.sh $< $@
	$(CHOWN) $@/rootfs

cache/uxgpro-%/image.tar: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image save --output $@ $(SOURCE_IMAGE)
