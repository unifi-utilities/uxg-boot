ARG VERSION
FROM joshuaspence/uxg-setup:${VERSION}-original
COPY docker-entrypoint.sh /usr/local/bin
