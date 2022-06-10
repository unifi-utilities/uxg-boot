IMAGE = joshuaspence/uxg-setup
SHELL = /bin/bash

check_defined = $(if $(value $1),$(value $1),$(error Undefined $1$(if $(value @), required by target `$@')))

default: image build push

.PHONY: image
image: cache/uxg-setup.json cache/uxg-setup.tar
	$(eval CMD = $(shell jq --raw-output '.Cmd | tojson' $(filter %.json,$^)))
	$(eval ENTRYPOINT = $(shell jq --raw-output '.Entrypoint | tojson' $(filter %.json,$^)))
	$(eval ENV = $(shell jq --raw-output '.Env | join(" ")' $(filter %.json,$^)))
	$(eval EXPOSE = $(shell jq --raw-output '.ExposedPorts | keys | join(" ")' $(filter %.json,$^)))
	$(eval LABEL = $(shell jq --raw-output '.Labels | to_entries | map("\(.key)=\(.value)") | join(" ")' $(filter %.json,$^)))
	$(eval VERSION = $(shell jq --raw-output '.Labels.version' $(filter %.json,$^)))

	docker import \
		--change 'EXPOSE $(EXPOSE)' \
		--change 'ENV $(ENV)' \
		--change 'ENTRYPOINT $(ENTRYPOINT)' \
		--change 'CMD $(CMD)' \
		--change 'LABEL $(LABEL)' \
		$(filter %.tar,$^) "$(IMAGE):$(VERSION)"

.PHONY: build
build: cache/uxg-setup.json
	$(eval VERSION = $(shell jq --raw-output '.Labels.version' $(filter %.json,$^)))
	docker build --build-arg VERSION=$(VERSION) --tag "$(IMAGE):$(VERSION)-1" .

.PHONY: push
push:
	docker push --all-tags "$(IMAGE)"

.PHONY: images
images:
	docker image ls "$(IMAGE)"

cache/uxg-setup.tar:
	mkdir --parents $(@D)
	ssh -o LogLevel=quiet $(call check_defined,DEVICE) $$'podman export --output /proc/self/fd/1 uxg-setup' > $@

# See https://github.com/moby/moby/issues/8334
cache/uxg-setup.json:
	mkdir --parents $(@D)
	ssh -o LogLevel=quiet $(call check_defined,DEVICE) $$'podman inspect --type image --format \'{{ json .Config }}\' $$(podman inspect --type container uxg-setup --format \'{{ .ImageID }}\')' > $@
