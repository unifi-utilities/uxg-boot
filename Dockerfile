ARG VERSION
FROM uxg-setup:${VERSION}

# TODO: Why are these needed?
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nodejs", "/usr/share/uxgpro-setup/app.js"]

COPY docker-entrypoint.sh /usr/local/bin
