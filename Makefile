IMAGE = joshuaspence/uxg-setup
SHELL = /bin/bash

default: image build push

.PHONY: image
image: cache/uxg-setup.json cache/uxg-setup.tar
	$(eval CMD = $(shell jq --raw-output '.Cmd | tojson' cache/uxg-setup.json))
	$(eval ENTRYPOINT = $(shell jq --raw-output '.Entrypoint | tojson' cache/uxg-setup.json))
	$(eval ENV = $(shell jq --raw-output '.Env | join(" ")' cache/uxg-setup.json))
	$(eval EXPOSE = $(shell jq --raw-output '.ExposedPorts | keys | join(" ")' cache/uxg-setup.json))
	$(eval LABEL = $(shell jq --raw-output '.Labels | to_entries | map("\(.key)=\(.value)") | join(" ")' cache/uxg-setup.json))
	$(eval VERSION = $(shell jq --raw-output '.Labels.version' cache/uxg-setup.json))

	docker import \
		--change 'EXPOSE $(EXPOSE)' \
		--change 'ENV $(ENV)' \
		--change 'ENTRYPOINT $(ENTRYPOINT)' \
		--change 'CMD $(CMD)' \
		--change 'LABEL $(LABEL)' \
		cache/uxg-setup.tar "$(IMAGE):$(VERSION)"

.PHONY: build
build: cache/uxg-setup.json
	$(eval VERSION = $(shell jq --raw-output '.Labels.version' cache/uxg-setup.json))
	docker build --build-arg VERSION=$(VERSION) --tag "$(IMAGE):$(VERSION)-1" .

.PHONY: push
push:
	docker push --all-tags "$(IMAGE)"

.PHONY: images
images:
	docker image ls "$(IMAGE)"

cache/uxg-setup.tar:
	mkdir --parents cache
	ssh -o LogLevel=quiet $(DEVICE) $$'podman export --output /proc/self/fd/1 uxg-setup' > $@

# See https://github.com/moby/moby/issues/8334
cache/uxg-setup.json:
	mkdir --parents cache
	ssh -o LogLevel=quiet $(DEVICE) $$'podman inspect --type image --format \'{{ json .Config }}\' $$(podman inspect --type container uxg-setup --format \'{{ .ImageID }}\')' > $@
