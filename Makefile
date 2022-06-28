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

define ubnt_fwupdate_api
https://fw-update.ubnt.com/api/$(1)?$\
$(subst $  ,&,$(foreach filter,product=unifi-firmware platform=UXGPRO channel=release $(2),filter=eq~~$(subst =,~~,$(filter))))&$\
$(subst $  ,&,$(foreach key,$(3),sort=$(key)))
endef

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
	$(eval FIRMWARE_VERSION = $(shell $(CURL) '$(call ubnt_fwupdate_api,firmware-latest)' | $(JQ) '._embedded.firmware[0].version | ltrimstr("v") | split("+")[0]'))
	$(MAKE) FIRMWARE_VERSION=$(FIRMWARE_VERSION)
endif

cache/uxgpro-%/firmware.bin: cache/uxgpro-%/firmware.json
	$(MKDIR) $(@D)
	$(CURL) --output $@ $$($(JQ) '._embedded.firmware[0]._links.data.href' $<)

cache/uxgpro-%/firmware.json:
	$(MKDIR) $(@D)
	$(CURL) --output $@ '$(call ubnt_fwupdate_api,firmware,version_major=$(word 1,$(subst ., ,$*)) version_minor=$(word 2,$(subst ., ,$*)) version_patch=$(word 3,$(subst ., ,$*)),-version)'

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
		--squash-all \
		.
