ARG BUILD_FROM
FROM $BUILD_FROM
COPY docker-entrypoint.sh /usr/local/bin
