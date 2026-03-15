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

# resolve menu version once for use by both menu and secure boot downloads
if [[ -z ${MENU_VERSION+x} ]]; then
  if [[ -f /config/menuversion.txt ]]; then
    MENU_VERSION=$(cat /config/menuversion.txt)
  else
    MENU_VERSION=$(curl -sL "https://api.github.com/repos/netbootxyz/netboot.xyz/releases/latest" | jq -r '.tag_name')
  fi
fi

# download menus if not found
if [[ ! -f /config/menus/remote/menu.ipxe ]]; then
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
  # cleanup
  echo -n "${MENU_VERSION}" > /config/menuversion.txt
  rm -f /tmp/menus.tar.gz
fi

# Secure Boot files (runs independently of menu download):
# - Signed EFI binaries are downloaded unmodified from the upstream iPXE
#   project release at https://github.com/ipxe/ipxe/releases (ipxeboot.tar.gz).
#   These include the Microsoft-signed shim and iPXE binaries signed by the
#   iPXE Secure Boot CA. They are not rebuilt or altered by netboot.xyz.
# - The autoexec.ipxe boot script is downloaded from the netboot.xyz release.
#   It is the only netboot.xyz-produced artifact in the Secure Boot chain.
# - IPXE_SB_VERSION can be overridden to pin a specific iPXE release version.
if [[ ! -d /config/menus/remote/secureboot-x86_64 ]]; then
  IPXE_SB_VERSION="${IPXE_SB_VERSION:-v2.0.0}"
  echo "[netbootxyz-init] Downloading Secure Boot binaries (iPXE ${IPXE_SB_VERSION})..."
  curl -o \
    /tmp/ipxeboot.tar.gz -sL \
    "https://github.com/ipxe/ipxe/releases/download/${IPXE_SB_VERSION}/ipxeboot.tar.gz"
  if [[ -f /tmp/ipxeboot.tar.gz ]] && [[ -s /tmp/ipxeboot.tar.gz ]]; then
    if tar xf /tmp/ipxeboot.tar.gz -C /tmp; then
      mkdir -p \
        /config/menus/remote/secureboot-x86_64 \
        /config/menus/remote/secureboot-arm64
      # x86_64 secure boot binaries
      for f in shimx64.efi ipxe-shim.efi ipxe.efi snponly.efi snponly-shim.efi; do
        if [[ -f "/tmp/ipxeboot/x86_64-sb/${f}" ]]; then
          cp "/tmp/ipxeboot/x86_64-sb/${f}" /config/menus/remote/secureboot-x86_64/
        else
          echo "[netbootxyz-init] Warning: ${f} not found in iPXE x86_64-sb archive"
        fi
      done
      # arm64 secure boot binaries
      for f in shimaa64.efi ipxe-shim.efi ipxe.efi snponly.efi snponly-shim.efi; do
        if [[ -f "/tmp/ipxeboot/arm64-sb/${f}" ]]; then
          cp "/tmp/ipxeboot/arm64-sb/${f}" /config/menus/remote/secureboot-arm64/
        else
          echo "[netbootxyz-init] Warning: ${f} not found in iPXE arm64-sb archive"
        fi
      done
      # download autoexec.ipxe boot script from netboot.xyz release
      if curl -o /tmp/autoexec.ipxe -fsSL \
        "https://github.com/netbootxyz/netboot.xyz/releases/download/${MENU_VERSION}/autoexec.ipxe"; then
        cp /tmp/autoexec.ipxe /config/menus/remote/secureboot-x86_64/autoexec.ipxe
        cp /tmp/autoexec.ipxe /config/menus/remote/secureboot-arm64/autoexec.ipxe
        rm -f /tmp/autoexec.ipxe
      else
        echo "[netbootxyz-init] autoexec.ipxe not available for ${MENU_VERSION}, skipping"
      fi
    else
      echo "[netbootxyz-init] Failed to extract iPXE Secure Boot archive, skipping"
    fi
    rm -rf /tmp/ipxeboot /tmp/ipxeboot.tar.gz
  else
    echo "[netbootxyz-init] iPXE Secure Boot archive not available, skipping"
  fi
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
shopt -s nullglob
for sbdir in /config/menus/remote/secureboot-*/; do
  cp -r "$sbdir" /config/menus/
done
shopt -u nullglob
if [ -d /config/menus/local ]; then
  for file in /config/menus/local/*; do
    [ -f "$file" ] && cp "$file" /config/menus/
  done
fi

# Ownership
chown -R nbxyz:nbxyz /config
