CAT    := cat
CHOWN  := sudo chown --recursive $(USER):$(USER)
CURL   := curl --fail --location --no-progress-meter
FIND   := find
JQ     := jq --raw-output --exit-status
PODMAN := podman
MKDIR  := @mkdir --parents
SKOPEO := skopeo

SOURCE_IMAGE := uxg-setup
TARGET_IMAGE := docker.io/joshuaspence/uxg-setup

MAKEFLAGS += --no-print-directory
MAKEFLAGS += --warn-undefined-variables

.DELETE_ON_ERROR:
.PHONY: build
.SECONDARY:

ifdef FIRMWARE_VERSION
build: cache/uxgpro-$(FIRMWARE_VERSION)/output.tar
ifdef DOCKER_PUSH
	$(SKOPEO) copy docker-archive:$< docker://$(TARGET_IMAGE):$$($(SKOPEO) inspect --config --raw docker-archive:$< | $(JQ) .config.Labels.version)
	$(SKOPEO) copy docker-archive:$< docker://$(TARGET_IMAGE):latest
endif
else
build:
	$(eval FIRMWARE_VERSION = $(shell $(CURL) --header 'X-Requested-With: XMLHttpRequest' https://www.ui.com/download/?product=uxg-pro | $(JQ) '.downloads | map(select(.category__slug == "firmware")) | max_by(.version) | .version'))
	$(MAKE) FIRMWARE_VERSION=$(FIRMWARE_VERSION)
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
	$(FIND) $@/rootfs -type c -delete

cache/uxgpro-%/input.tar: cache/uxgpro-%/fs
	$(PODMAN) --root $</rootfs/var/lib/containers/storage image save --output $@ $(SOURCE_IMAGE)

cache/uxgpro-%/output.tar: cache/uxgpro-%/output.txt
	$(PODMAN) save --output $@ $$($(CAT) $<)

cache/uxgpro-%/output.txt: cache/uxgpro-%/input.tar
	$(PODMAN) image load --input $<
	$(PODMAN) image build \
		--from $$($(SKOPEO) inspect --raw docker-archive:$< | $(JQ) .config.digest) \
		--iidfile $@ \
		--label source_firmware=$* \
		.
