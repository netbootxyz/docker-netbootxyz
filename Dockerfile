# Build stage - Download and prepare webapp
FROM alpine:3.22.0 AS build

# Set version label
ARG WEBAPP_VERSION

# Install build dependencies with virtual package for easy cleanup
RUN apk add --no-cache --virtual .build-deps \
    bash \
    curl \
    git \
    jq \
    npm \
    && mkdir /app \
    # Determine webapp version if not provided
    && if [ -z ${WEBAPP_VERSION+x} ]; then \
        WEBAPP_VERSION=$(curl -sX GET "https://api.github.com/repos/netbootxyz/webapp/releases/latest" \
        | awk '/tag_name/{print $4;exit}' FS='[""]'); \
    fi \
    # Download and extract webapp
    && curl -o /tmp/webapp.tar.gz -L \
        "https://github.com/netbootxyz/webapp/archive/${WEBAPP_VERSION}.tar.gz" \
    && tar xf /tmp/webapp.tar.gz -C /app/ --strip-components=1 \
    # Install only production dependencies
    && cd /app \
    && npm install --omit=dev --no-audit --no-fund \
    # Clean up build artifacts and cache
    && npm cache clean --force \
    && rm -rf /tmp/* \
    && apk del .build-deps

# Production stage - Final container
FROM alpine:3.22.0

# Build arguments for labels
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

# Enhanced container labels following OCI spec
LABEL org.opencontainers.image.title="netboot.xyz" \
      org.opencontainers.image.description="Your favorite operating systems in one place. A network-based bootable operating system installer based on iPXE." \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="netboot.xyz" \
      org.opencontainers.image.url="https://netboot.xyz" \
      org.opencontainers.image.source="https://github.com/netbootxyz/docker-netbootxyz" \
      org.opencontainers.image.licenses="Apache-2.0" \
      maintainer="antonym"

# Install runtime dependencies and configure system in a single layer
RUN apk add --no-cache \
    # Core utilities
    bash \
    busybox \
    curl \
    envsubst \
    jq \
    tar \
    # Network services
    dnsmasq \
    nginx \
    nodejs \
    # System services
    shadow \
    sudo \
    supervisor \
    syslog-ng \
    # Security tools
    gosu \
    # Runtime libraries
    nghttp2-dev \
    # Create required directories
    && mkdir -p /app /config /defaults \
    # Remove unnecessary packages to reduce size
    && rm -rf /var/cache/apk/*

# Copy webapp from build stage
COPY --from=build /app /app

# Environment variables with defaults
ENV TFTPD_OPTS='' \
    NGINX_PORT='80' \
    WEB_APP_PORT='3000' \
    NODE_ENV='production' \
    NPM_CONFIG_CACHE='/tmp/.npm' \
    PUID='1000' \
    PGID='1000'

EXPOSE 69/udp
EXPOSE 80
EXPOSE 3000

# Copy configuration files and scripts
COPY --chown=root:root root/ /

# Make scripts executable
RUN chmod +x /start.sh /init.sh /healthcheck.sh /usr/local/bin/dnsmasq-wrapper.sh

# Enhanced health check with better timing for slow systems
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

# Use exec form for better signal handling
CMD ["/start.sh"]
