# uxg-boot

Enables custom boot scripts for the [UniFi UXG-Pro][uxg-pro]. Inspired by
[`on-boot-script`][on-boot-script] from [`udm-utilities`][udm-utilities] and
based on ideas from boostchicken-dev/udm-utilities#356. Intended to be fully
compatible with [`udm-utilities`][udm-utilities], such that all of the scripts
from the original repository should work verbatim.

Tested on the following firmware versions:

  - 1.11.0
  - 1.12.19
  - 1.13.6

## Installation

### Automatic

You can install `uxg-boot` by running the following command on your UXG-Pro.

```sh
curl -fLSs https://raw.githubusercontent.com/unifi-utilities/uxg-boot/master/install.sh | sh
```

### Manual

```sh
VERSION=$(podman image inspect --format '{{ .Labels.version }}' uxg-setup:default)
uxg-setup update joshuaspence/uxg-setup:$(VERSION)
```

## Uninstallation

### Automatic

```sh
curl -fLSs https://raw.githubusercontent.com/unifi-utilities/uxg-boot/master/install.sh | sh -s uninstall
```

### Manual

```sh
podman image tag uxg-setup:latest uxg-setup:default
uxg-setup reset
```

## Usage

Once installed, any executable files in `/mnt/data/on_boot.d` will be executed
when the `uxg-setup` container is started. As the `uxg-setup` container could
be started multiple times (e.g. by being restarted), boot scripts should be
idempotent.

```sh
#!/bin/sh

podman container exists multicast-relay || podman create --detach --name multicast-relay --network host --restart always scyto/multicast-relay:latest
podman start multicast-relay
```

[on-boot-script]: https://github.com/boostchicken-dev/udm-utilities/blob/master/on-boot-script/README.md
[udm-utilities]: https://github.com/boostchicken-dev/udm-utilities
[uxg-pro]: https://store.ui.com/products/unifi-next-generation-gateway-professional
