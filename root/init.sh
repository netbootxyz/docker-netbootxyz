#!/bin/bash

# Configure user and group IDs
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "[init] Setting up user nbxyz with PUID=${PUID} and PGID=${PGID}"

# Create group with specified GID if it doesn't exist
if ! getent group ${PGID} > /dev/null 2>&1; then
    groupadd -g ${PGID} nbxyz
else
    echo "[init] Group with GID ${PGID} already exists"
fi

# Create user with specified UID if it doesn't exist
if ! getent passwd ${PUID} > /dev/null 2>&1; then
    useradd -u ${PUID} -g ${PGID} -d /config -s /bin/false nbxyz
else
    echo "[init] User with UID ${PUID} already exists"
fi

# Add to users group for compatibility
usermod -a -G users nbxyz 2>/dev/null || true

# make our folders
mkdir -p \
  /assets \
  /config/nginx/site-confs \
  /config/log/nginx \
  /run \
  /var/lib/nginx/logs \
  /var/lib/nginx/tmp/client_body \
  /var/tmp/nginx \
  /var/log

# copy config files
[[ ! -f /config/nginx/nginx.conf ]] && \
  cp /defaults/nginx.conf /config/nginx/nginx.conf
[[ ! -f /config/nginx/site-confs/default ]] && \
  envsubst '${NGINX_PORT}' < /defaults/default > /config/nginx/site-confs/default

# Set up permissions for all directories that services need to write to
chown -R nbxyz:nbxyz /assets
chown -R nbxyz:nbxyz /var/lib/nginx
chown -R nbxyz:nbxyz /config/log/nginx
chown -R nbxyz:nbxyz /run
chown -R nbxyz:nbxyz /var/tmp/nginx
chown -R nbxyz:nbxyz /var/log/nginx

# create local logs dir
mkdir -p \
  /config/menus/remote \
  /config/menus/local

# download menus if not found
if [[ ! -f /config/menus/remote/menu.ipxe ]]; then
  if [[ -z ${MENU_VERSION+x} ]]; then
    MENU_VERSION=$(curl -sL "https://api.github.com/repos/netbootxyz/netboot.xyz/releases/latest" | jq -r '.tag_name')
  fi
  echo "[netbootxyz-init] Downloading netboot.xyz at ${MENU_VERSION}"
  # menu files
  curl -o \
    /config/endpoints.yml -sL \
    "https://raw.githubusercontent.com/netbootxyz/netboot.xyz/${MENU_VERSION}/endpoints.yml"
  curl -o \
    /tmp/menus.tar.gz -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/menus.tar.gz"
  tar xf \
    /tmp/menus.tar.gz -C \
    /config/menus/remote
  # boot files
  curl -o \
    /config/menus/remote/netboot.xyz.kpxe -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz.kpxe"
  curl -o \
    /config/menus/remote/netboot.xyz-undionly.kpxe -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-undionly.kpxe"
  curl -o \
    /config/menus/remote/netboot.xyz.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz.efi"
  curl -o \
    /config/menus/remote/netboot.xyz-snp.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-snp.efi"
  curl -o \
    /config/menus/remote/netboot.xyz-snponly.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-snponly.efi"
  curl -o \
    /config/menus/remote/netboot.xyz-arm64.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-arm64.efi"
  curl -o \
    /config/menus/remote/netboot.xyz-arm64-snp.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-arm64-snp.efi"
  curl -o \
    /config/menus/remote/netboot.xyz-arm64-snponly.efi -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/netboot.xyz-arm64-snponly.efi"
  # secure boot files
  echo "[netbootxyz-init] Downloading Secure Boot binaries..."
  curl -o \
    /tmp/secureboot-x86_64.tar.gz -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/secureboot-x86_64.tar.gz"
  if [ -f /tmp/secureboot-x86_64.tar.gz ] && [ -s /tmp/secureboot-x86_64.tar.gz ]; then
    tar xf /tmp/secureboot-x86_64.tar.gz -C /config/menus/remote
  else
    echo "[netbootxyz-init] Secure Boot x86_64 tarball not available for ${MENU_VERSION}, skipping"
  fi
  curl -o \
    /tmp/secureboot-arm64.tar.gz -sL \
    "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/secureboot-arm64.tar.gz"
  if [ -f /tmp/secureboot-arm64.tar.gz ] && [ -s /tmp/secureboot-arm64.tar.gz ]; then
    tar xf /tmp/secureboot-arm64.tar.gz -C /config/menus/remote
  else
    echo "[netbootxyz-init] Secure Boot ARM64 tarball not available for ${MENU_VERSION}, skipping"
  fi
  # cleanup
  echo -n "${MENU_VERSION}" > /config/menuversion.txt
  rm -f /tmp/menus.tar.gz /tmp/secureboot-*.tar.gz
fi

# Apply menu layering: remote files first, then local overrides on top
# This mirrors the webapp's layermenu() function and ensures user
# customizations (boot.cfg, local-vars.ipxe, etc.) persist across
# container restarts
echo "[netbootxyz-init] Applying menu layers..."
for file in /config/menus/remote/*; do
  [ -f "$file" ] && cp "$file" /config/menus/
done
# Copy Secure Boot subdirectories if present
for sbdir in /config/menus/remote/secureboot-*/; do
  [ -d "$sbdir" ] && cp -r "$sbdir" /config/menus/
done
if [ -d /config/menus/local ]; then
  for file in /config/menus/local/*; do
    [ -f "$file" ] && cp "$file" /config/menus/
  done
fi

# Ownership
chown -R nbxyz:nbxyz /config
