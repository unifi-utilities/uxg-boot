#!/bin/sh

# shellcheck shell=ash
# shellcheck disable=SC3010,SC3020

set -o errexit
set -o nounset
set -o pipefail

LOCAL_IMAGE='uxg-setup:default'
REMOTE_IMAGE='joshuaspence/uxg-setup'

depends_on() {
  command -v "${1}" &>/dev/null || {
    echo "Missing dependency: \`${1}\`" >&2
    return 1
  }
}

header() {
  cat <<'EOF'
 _   ___  ______   ____              _
| | | \ \/ / ___| | __ )  ___   ___ | |_
| | | |\  / |  _  |  _ \ / _ \ / _ \| __|
| |_| |/  \ |_| | | |_) | (_) | (_) | |_
 \___//_/\_\____| |____/ \___/ \___/ \__|

EOF
}

install() {
  if is_installed; then
    echo 'UXG-Boot is already installed.' >&2
    return 1
  fi

  IMAGE_ID=$(podman image inspect --format '{{ .ID }}' "${LOCAL_IMAGE}")
  IMAGE_VERSION=$(podman image inspect --format '{{ .Labels.version }}' "${LOCAL_IMAGE}")

  if [[ "${IMAGE_VERSION}" == '<no value>' ]]; then
    echo "Unable to determine version of '${LOCAL_IMAGE}'" >&2
    return 1
  fi

  echo "Updating ${LOCAL_IMAGE} (${IMAGE_ID}) to ${REMOTE_IMAGE}:${IMAGE_VERSION}"
  uxg-setup update "${REMOTE_IMAGE}:${IMAGE_VERSION}"
}

is_installed() {
  podman image inspect --format '{{ range $k, $v := .RepoTags }}{{ $v }}{{ "\n" }}{{ end }}' "${LOCAL_IMAGE}" 2>/dev/null | grep -q "${REMOTE_IMAGE}"
}

uninstall() {
  if ! is_installed; then
    echo 'UXG-Boot is not installed.' >&2
    return 1
  fi

  echo "Stopping uxg-setup"
  uxg-setup stop

  for IMAGE in $(podman image list --quiet "${REMOTE_IMAGE}"); do
    # NOTE: I am not sure why the image ID end with `false`.
    IMAGE="${IMAGE%false}"

    echo "Removing ${REMOTE_IMAGE} (${IMAGE})"
    podman image rm --force "${IMAGE}"
  done

  echo "Resetting uxg-setup"
  uxg-setup reset
}

header
depends_on ubnt-device-info
depends_on podman

if [[ $(ubnt-device-info family_short) != 'UXG' ]]; then
  echo "Unsupported device: $(ubnt-device-info model)" >&2
  exit 1
fi

if ! podman image exists "${LOCAL_IMAGE}"; then
  echo "Image '${LOCAL_IMAGE}' not found." >&2
  exit 1
fi

case "${1:-install}" in
  install)
    install
    ;;

  uninstall)
    uninstall
    ;;

  *)
    echo "Invalid command: ${1}" >&2
    exit 1
    ;;
esac
