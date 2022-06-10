SHELL = /bin/bash

.PHONY: image
image: uxg-setup.json uxg-setup.tar
	$(eval CMD = $(shell jq --raw-output '.Cmd | tojson' uxg-setup.json))
	$(eval ENTRYPOINT = $(shell jq --raw-output '.Entrypoint | tojson' uxg-setup.json))
	$(eval ENV = $(shell jq --raw-output '.Env | join(" ")' uxg-setup.json))
	$(eval EXPOSE = $(shell jq --raw-output '.ExposedPorts | keys | join(" ")' uxg-setup.json))
	$(eval LABEL = $(shell jq --raw-output '.Labels | to_entries | map("\(.key)=\(.value)") | join(" ")' uxg-setup.json))
	$(eval VERSION = $(shell jq --raw-output '.Labels.version' uxg-setup.json))

	docker import \
		--change 'EXPOSE $(EXPOSE)' \
		--change 'ENV $(ENV)' \
		--change 'ENTRYPOINT $(ENTRYPOINT)' \
		--change 'CMD $(CMD)' \
		--change 'LABEL $(LABEL)' \
		uxg-setup.tar "joshuaspence/uxg-setup:$(VERSION)"
	docker tag "joshuaspence/uxg-setup:$(VERSION)" joshuaspence/uxg-setup:latest

.PHONY: build
build:
	docker build --tag joshuaspence/uxg-setup:latest .

.PHONY: push
push:
	docker push --all-tags joshuaspence/uxg-setup

uxg-setup.tar:
	ssh -o LogLevel=quiet $(DEVICE) $$'podman export --output /proc/self/fd/1 uxg-setup' > $@

# See https://github.com/moby/moby/issues/8334
uxg-setup.json:
	ssh -o LogLevel=quiet $(DEVICE) $$'podman inspect --type image --format \'{{ json .Config }}\' $$(podman inspect --type container uxg-setup --format \'{{ .ImageID }}\')' > $@
