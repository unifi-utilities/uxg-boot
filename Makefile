CHOWN  := sudo chown --recursive $(USER):$(USER)
CURL   := curl --fail --location --no-progress-meter
JQ     := jq --raw-output --exit-status
PODMAN := podman
MKDIR  := @mkdir --parents

SOURCE_IMAGE := uxg-setup
TARGET_IMAGE := docker.io/joshuaspence/uxg-setup

.DELETE_ON_ERROR:
.PHONY: build push
.SECONDARY:

# TODO: Allow setting `FIRMWARE_VERSION=latest`.
build: cache/uxgpro-$(FIRMWARE_VERSION)/image.tar cache/uxgpro-$(FIRMWARE_VERSION)/image.mk
	$(eval include cache/uxgpro-$(FIRMWARE_VERSION)/image.mk)
	$(PODMAN) image load --input cache/uxgpro-$(FIRMWARE_VERSION)/image.tar
	$(PODMAN) image build --build-arg BUILD_FROM=$(SOURCE_DIGEST) --tag $(TARGET_IMAGE):$(SOURCE_VERSION) .

# TODO: Don't push older images.
push:
	$(eval include cache/uxgpro-$(FIRMWARE_VERSION)/image.mk)
	$(PODMAN) image push $(TARGET_IMAGE):$(SOURCE_VERSION)

cache/uxgpro-%/firmware.bin: cache/uxgpro-%/firmware.json
	$(MKDIR) $(@D)
	$(CURL) --output $@ $$($(JQ) .file_path $<)

cache/uxgpro-%/firmware.json:
	$(MKDIR) $(@D)
	$(CURL) --header 'X-Requested-With: XMLHttpRequest' https://www.ui.com/download/?product=uxg-pro | $(JQ) --arg version $* '.downloads[] | select(.category__slug == "firmware" and .version == $$version)' > $@

cache/uxgpro-%/fs: cache/uxgpro-%/firmware.bin
	firmware-mod-kit/extract-firmware.sh $< $@
	$(CHOWN) $@/rootfs

cache/uxgpro-%/image.mk: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image inspect --format 'SOURCE_DIGEST := {{ .ID }}{{ "\n" }}SOURCE_VERSION := {{ .Config.Labels.version }}' $(SOURCE_IMAGE) > $@

cache/uxgpro-%/image.tar: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image save --output $@ $(SOURCE_IMAGE)
