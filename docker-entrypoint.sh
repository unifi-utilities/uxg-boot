#!/bin/sh

# Wait for SSH to be ready.
timeout 20 bash <<- 'EOF'
	until printf '' 2>/dev/null >/dev/tcp/localhost/22; do
		sleep 1
	done
EOF

# Execute boot scripts.
ssh -o StrictHostKeyChecking=no -q localhost <<- 'EOF'
	mkdir -p /mnt/data/on_boot.d
	find -L /mnt/data/on_boot.d -mindepth 1 -maxdepth 1 -type f -print0 | sort -z | xargs -0 -r -n 1 -- sh -c "$(cat <<- 'EOT'
		if test -x "${0}"; then
			echo "running ${0}"
			"${0}"
		else
			case "${0}" in
				*.sh)
					echo "sourcing ${0}"
					. "${0}"
					;;

				*)
					echo "ignoring ${0}"
					;;
			esac
		fi
	EOT
	)"
EOF

set -e

if [ "${1#-}" != "${1}" ] || [ -z "$(command -v "${1}")" ]; then
  set -- node "$@"
fi

exec "$@"
