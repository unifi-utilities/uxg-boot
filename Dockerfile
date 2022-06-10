ARG VERSION
FROM joshuaspence/uxg-setup:${VERSION}

COPY docker-entrypoint.sh /usr/local/bin
