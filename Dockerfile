FROM alpine:3.19

# set version label
ARG BUILD_DATE
ARG VERSION
ARG WEBAPP_VERSION

LABEL build_version="netboot.xyz version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="antonym"
LABEL org.opencontainers.image.description netboot.xyz official docker container - Your favorite operating systems in one place. A network-based bootable operating system installer based on iPXE.

RUN \
 apk add --no-cache \
   bash \
   busybox \
   curl \
   envsubst \
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
   dnsmasq && \
 apk add --no-cache --virtual=build-dependencies \
   npm && \
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
 curl -o /tmp/webapp.tar.gz -L \
        "https://github.com/netbootxyz/webapp/archive/${WEBAPP_VERSION}.tar.gz" && \
 tar xf /tmp/webapp.tar.gz -C \
        /app/ --strip-components=1 && \
 npm install --prefix /app && \
 apk del --purge build-dependencies && \
 rm -rf /tmp/*

ENV TFTPD_OPTS=''
ENV NGINX_PORT='80'
ENV WEB_APP_PORT='3000'

EXPOSE 69/udp
EXPOSE 80
EXPOSE 3000

COPY root/ /

# default command
CMD ["sh","/start.sh"]
