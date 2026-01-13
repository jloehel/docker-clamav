ARG OS_FLAVOR=alpine
ARG OS_VERSION=3.23

FROM ${OS_FLAVOR}:${OS_VERSION}

ARG ARCH=amd64
ARG OS=linux
ARG OS_FLAVOR=alpine
ARG OS_VERSION=3.23
ARG IMAGE_VERSION=2.0.0
ARG IMAGE_DESCRIPTION="Image containing ClamAV and ClamAV Unofficial Signatures Updater maintained by eXtremeSHOK.com"
ARG APP_NAME=clamav
ARG APP_NAME_UPPER=CLAMAV
ARG APP_VERSION=1.4.3
ARG UNOFFICIAL_SIGS_VERSION=7.2.5
ARG APP_USERNAME=clamav
ARG APP_USER_DEFAULT=1001

LABEL maintainer="Jürgen Löhel <juergen@loehel.de>"
LABEL org.opencontainers.image.title="ClamAV customized docker image by jloehel"
LABEL org.opencontainers.image.authors="Jürgen Löhel"
LABEL org.opencontainers.image.source="https://github.com/jloehel/docker-${APP_NAME}"
LABEL org.opencontainers.image.url="https://github.com/jloehel/docker-${APP_NAME}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.${OS_FLAVOR}.version="${OS_VERSION}"
LABEL org.clamav.version="${APP_VERSION}"
LABEL org.clamav-unofficial-sigs.version="${UNOFFICIAL_SIGS_VERSION}"

ENV ARCH="${ARCH}" \
    OS="${OS}" \
    OS_FLAVOR="${OS_FLAVOR}" \
    OS_VERSION="${OS_VERSION}" \
    APP_NAME="${APP_NAME}" \
    APP_VERSION="${APP_VERSION}" \
    APP_USERNAME="${APP_USERNAME}" \
    CLAMAV_HOME="/clamav/data" \
    NSS_WRAPPER_GROUP="/opt/${APP_NAME}/nss_group" \
    NSS_WRAPPER_PWD="/opt/${APP_NAME}/nss_passwd"

COPY ./overlay/base /
COPY ./overlay/${OS_FLAVOR} /

RUN set -eux; \
    . /build/update.sh && \
    . /build/install-dependencies.sh && \
    . /build/install-app.sh && \
    . /build/clean.sh

EXPOSE 3310

WORKDIR /opt/${APP_NAME}/
USER ${APP_USER_DEFAULT}
VOLUME ["/clamav/data"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 CMD /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/run.sh"]
