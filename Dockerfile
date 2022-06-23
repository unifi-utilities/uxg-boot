ARG SOURCE_VERSION
FROM joshuaspence/uxg-setup:${SOURCE_VERSION}-original
COPY docker-entrypoint.sh /usr/local/bin
