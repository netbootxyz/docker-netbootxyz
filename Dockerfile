FROM alpine:3.16

# set version label
ARG BUILD_DATE
ARG VERSION
ARG WEBAPP_VERSION
LABEL build_version="netboot.xyz version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="antonym"

RUN \
 apk add --no-cache --virtual=build-dependencies \
        nodejs npm && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
        bash \
        busybox \
        curl \
        git \
        jq \
        nghttp2-dev \
        nginx \
        nodejs \
        shadow \
        sudo \
        supervisor \
        syslog-ng \
        tar \
        tftp-hpa

RUN \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false nbxyz && \
 usermod -G users nbxyz && \
 mkdir /app \
       /config \
       /defaults && \
 if [ -z ${WEBAPP_VERSION+x} ]; then \
        WEBAPP_VERSION=$(curl -sX GET "https://api.github.com/repos/netbootxyz/webapp/releases/latest" \
        | awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/webapp.tar.gz -L \
        "https://github.com/netbootxyz/webapp/archive/${WEBAPP_VERSION}.tar.gz" && \
 tar xf \
 /tmp/webapp.tar.gz -C \
        /app/ --strip-components=1 && \
 npm config set unsafe-perm true && \
 npm install --prefix /app

ENV TFTPD_OPTS=''

EXPOSE 3000

COPY root/ /

# default command
CMD ["sh","/start.sh"]
