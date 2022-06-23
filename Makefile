CHOWN  := sudo chown --recursive $(USER):$(USER)
CURL   := curl --fail --location --no-progress-meter
PODMAN := podman
MKDIR  := @mkdir --parents

SOURCE_IMAGE := localhost/uxg-setup
TARGET_IMAGE := joshuaspence/uxg-setup

FIRMWARE_1.11.0_SLUG  := 5d22
FIRMWARE_1.11.0_HASH  := a66138b5dd2c4060a99b25b90ceee8dc
FIRMWARE_1.12.19_SLUG := 2ee2
FIRMWARE_1.12.19_HASH := 45c1b1b0b5f84bc191310823d7d99baf
UXGPRO_FIRMWARE_URL    = https://fw-download.ubnt.com/data/unifi-firmware/$(FIRMWARE_$1_SLUG)-UXGPRO-$1-$(FIRMWARE_$1_HASH).bin

.PHONY: build
.SECONDARY:

# TODO: Allow setting `FIRMWARE_VERSION=latest`.
build: cache/uxgpro-$(FIRMWARE_VERSION)/image.tar cache/uxgpro-$(FIRMWARE_VERSION)/image.mk
	$(eval include cache/uxgpro-$(FIRMWARE_VERSION)/image.mk)
	$(PODMAN) image load --input cache/uxgpro-$(FIRMWARE_VERSION)/image.tar
	$(PODMAN) image tag $(SOURCE_DIGEST) $(TARGET_IMAGE):$(SOURCE_VERSION)-original
	$(PODMAN) image build --build-arg SOURCE_VERSION=$(SOURCE_VERSION) --tag $(TARGET_IMAGE):$(SOURCE_VERSION) .

# TODO: Don't push older images.
push:
	$(eval include cache/uxgpro-$(FIRMWARE_VERSION)/image.mk)
	$(PODMAN) image push $(TARGET_IMAGE):$(SOURCE_VERSION)-original docker.io/$(TARGET_IMAGE):$(SOURCE_VERSION)-original
	$(PODMAN) image push $(TARGET_IMAGE):$(SOURCE_VERSION) docker.io/$(TARGET_IMAGE):$(SOURCE_VERSION)

cache/uxgpro-%/firmware.bin:
	$(MKDIR) $(@D)
	$(CURL) --output $@ $(call UXGPRO_FIRMWARE_URL,$*)

cache/uxgpro-%/fs: cache/uxgpro-%/firmware.bin
	firmware-mod-kit/extract-firmware.sh $< $@
	$(CHOWN) $@/rootfs

cache/uxgpro-%/image.mk: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image inspect --format 'SOURCE_DIGEST := {{ .ID }}{{ "\n" }}SOURCE_VERSION := {{ .Config.Labels.version }}' $(SOURCE_IMAGE) > $@

cache/uxgpro-%/image.tar: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image save --output $@ $(SOURCE_IMAGE)
