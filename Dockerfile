ARG ALPINE_VERSION=3.17.0

FROM amd64/alpine:${ALPINE_VERSION}
LABEL maintainer="Jürgen Löhel <juergen@loehel.de>"
LABEL org.opencontainers.image.title="Private ClamAV Container"
LABEL org.opencontainers.image.authors="Jürgen Löhel"
LABEL org.opencontainers.image.source="https://github.com/jloehel/docker-clamav"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/jloehel/clamav"
LABEL org.opencontainers.image.version="1.2.4"
LABEL org.opencontainers.image.description="Image containing ClamAV and ClamAV Unofficial Signatures Updater maintained by eXtremeSHOK.com"
LABEL org.opencontainers.image.vendor="private"
LABEL org.clamav.version="0.105.1-r0"
LABEL org.clamav-unofficial-sigs.version="7.2.5"
LABEL org.alpine.version=${ALPINE_VERSION}

EXPOSE 3310

ENV OS_ARCH="amd64" \
    OS_FLAVOR="alpine-${ALPINE_VERSION}" \
    OS_NAME="linux"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["clamd"]

RUN set -eux; \
    apk update \
    && apk add --no-cache \
        clamav=0.105.1-r0 \
        clamav-libunrar \
        wget \
        curl \
        bash \
        tar \
        bind-tools \
        rsync \
        ncurses \
    && rm -rf /var/cache/apk/* /usr/src/* \
    && mkdir -p /var/run/clamav/ \
    && mkdir -p /data \
    && mkdir -p /usr/local/sbin/ \
    && mkdir -p /etc/clamav-unofficial-sigs/ \
    && mkdir -p /var/lib/clamav-unofficial-sigs/ \
    && chown clamav:clamav /var/run/clamav \
    && chown clamav:clamav /data \
    && chown clamav:clamav /entrypoint.sh \
    && chown clamav:clamav /var/lib/clamav-unofficial-sigs \
    && chmod u+x /entrypoint.sh \
    && curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -o /usr/local/sbin/clamav-unofficial-sigs \
    && curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -o /etc/clamav-unofficial-sigs/master.conf \
    && curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf -o /etc/clamav-unofficial-sigs/user.conf \
    && chmod 755 /usr/local/sbin/clamav-unofficial-sigs

COPY ./overlay /

RUN /usr/local/sbin/clamav-unofficial-sigs --install-logrotate \
    && /usr/local/sbin/clamav-unofficial-sigs --install-man \
    && /usr/local/sbin/clamav-unofficial-sigs --install-cron

WORKDIR /data
USER clamav
VOLUME ["/data"]
