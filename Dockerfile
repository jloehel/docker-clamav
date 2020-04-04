ARG ALPINE_VERSION=3.11

FROM amd64/alpine:${ALPINE_VERSION}
LABEL maintainer="Jürgen Löhel <juergen@loehel.de>"
LABEL org.opencontainers.image.title="Private ClamAV Container"
LABEL org.opencontainers.image.authors="Jürgen Löhel"
LABEL org.opencontainers.image.source="https://github.com/jloehel/docker-clamav"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/jloehel/clamav"
LABEL org.opencontainers.image.version="1.0.1"
LABEL org.opencontainers.image.description="Image containing ClamAV and ClamAV Unofficial Signatures Updater maintained by eXtremeSHOK.com"
LABEL org.opencontainers.image.vendor="private"
LABEL org.clamav.version="devel"
LABEL org.clamav-unofficial-sigs.version="7.0.1"
LABEL org.alpine.version="3.11"

EXPOSE 3310

ENV OS_ARCH="amd64" \
    OS_FLAVOR="alpine-3.11" \
    OS_NAME="linux"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["clamd"]

RUN set -eux; \
    apk update \
    && apk add --no-cache \
        gcc \
        g++ \
        make \
        autoconf \
        automake \
        libtool \
        linux-headers \
        bash \
        zlib-dev \
        fts-dev \
        openssl-dev \
        pcre2-dev \
        bzip2-dev \
        libxml2-dev \
        curl-dev \
        json-c-dev \
        ncurses-dev \
        libmilter-dev \
        libmilter \
        check-dev \
        check \
        libmspack-dev \
        python-dev \
        git \
        wget \
        curl \
        bash \
        tar \
        bind-tools \
        rsync \
        ncurses \
        vim \
        bash \
    && cd /tmp && git clone https://github.com/Cisco-Talos/clamav-devel \
    && cd /tmp/clamav-devel \
    && export CFLAGS="-fmessage-length=0 -grecord-gcc-switches -O3 -D_FORTIFY_SOURCE=2 -fstack-protector -funwind-tables -fasynchronous-unwind-tables -fPIE -fno-strict-aliasing" \
    && export CXXFLAGS="-fmessage-length=0 -grecord-gcc-switches -O3 -D_FORTIFY_SOURCE=2 -fstack-protector -funwind-tables -fasynchronous-unwind-tables -fPIE -fno-strict-aliasing -std=gnu++98" \
    && export LDFLAGS="-pie" \
    && export LIBS="-lfts" \
    && ./configure \
		    --prefix=/usr \
		    --libdir=/usr/lib \
		    --sysconfdir=/etc/clamav \
		    --mandir=/usr/share/man \
		    --infodir=/usr/share/info \
		    --without-iconv \
		    --disable-llvm \
		    --with-user=clamav \
		    --with-group=clamav \
        --with-dbdir=/data \
		    --enable-clamdtop \
		    --enable-bigstack \
		    --with-pcre \
		    --enable-milter \
		    --enable-clamonacc \
        --enable-check \
    && make \
    && make check \
    && make install \
    && groupadd clamav \
    && useradd -g clamav -s /bin/false -c "Clam Antivirus" clamav \
    && install -d -m755 /data \
    && mkdir -p -m 0755 /var/run/clamav \
    && mkdir -p /var/spool/amavis \
    && chown clamav:clamav /var/run/clamav \
    && chown clamav:clamav /data \
    && find / -type f -name "*.la" -delete -print \
    && sed -i -e "s:^\(Example\):\# \1:" \
		          -e "s:.*\(PidFile\) .*:\1 /run/clamav/freshclam.pid:" \
              -e "s:.*\(DatabaseOwner\) .*:\1 clamav:" \
              -e "s:^\#\(UpdateLogFile\) .*:\1 /var/log/clamav/freshclam.log:" \
              -e "s:^\#\(NotifyClamd\).*:\1 /etc/clamav/clamd.conf:" \
              -e "s:^\#\(ScriptedUpdates\).*:\1 yes:" \
              -e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
		  /etc/clamav/freshclam.conf.sample \
	  && sed -i -e "s:^\(Example\):\# \1:" \
              -e "s:.*\(PidFile\) .*:\1 /run/clamav/clamd.pid:" \
              -e "s:.*\(LocalSocket\) .*:\1 /run/clamav/clamd.sock:" \
              -e "s:.*\(User\) .*:\1 clamav:" \
              -e "s:^\#\(LogFile\) .*:\1 /var/log/clamav/clamd.log:" \
              -e "s:^\#\(LogTime\).*:\1 yes:" \
	            -e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
		  /etc/clamav/clamd.conf.sample \
    && cd /etc/clamav \
    && mv clamd.conf.sample clamd.conf \
    && mv clamav-milter.conf.sample clamav-milter.conf \
    && mv freshclam.conf.sample freshclam.conf \
    && cd / \
    && rm -rf /var/cache/apk/* /usr/src/* \
    && mkdir -p /usr/local/sbin/ \
    && mkdir -p /etc/clamav-unofficial-sigs/ \
    && mkdir -p /var/lib/clamav-unofficial-sigs/ \
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
