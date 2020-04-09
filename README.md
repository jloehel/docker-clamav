# Docker image for ClamAV and unofficial signatures from https://eXtremeSHOK.com
This Dockerfile adds ClamAV and the unofficial Signatures to a Docker Image.
Clamd is listening on `0.0.0.0`, `TCP/3310.`

## Supported tags and respective Dockerfile links
* `devel`
* `0.102.1-alpine-3.11-r2`, `latest`
* `0.102.1-alpine-3.11-r1`,

## Devel Image
```
export CFLAGS="-fmessage-length=0 -grecord-gcc-switches -O3 -D_FORTIFY_SOURCE=2 -fstack-protector -funwind-tables -fasynchronous-unwind-tables -fPIE -fno-strict-aliasing"
export CXXFLAGS="-fmessage-length=0 -grecord-gcc-switches -O3 -D_FORTIFY_SOURCE=2 -fstack-protector -funwind-tables -fasynchronous-unwind-tables -fPIE -fno-strict-aliasing -std=gnu++98"
export LDFLAGS="-pie"
export LIBS="-lfts"
./configure \
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
    --enable-check
```


## Docker-compose example
```
version: '3.4'

services:
  clamav:
    image: jloehel/clamav:latest
    hostname: clamav
    container_name: clamav
    restart: unless-stopped
    volumes:
      - clamav_data:/data:Z
    networks:
      internal-network:
        aliases:
        - clamav

volumes:
  clamav_data:

networks:
  internal-network:
```
