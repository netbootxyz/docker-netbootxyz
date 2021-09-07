# docker-netbootxyz

## Overview

The netboot.xyz docker image allows you to easily set up a local instance of netboot.xyz with a single command.  The container is built from Alpine Linux and contains several components:

* netboot.xyz [webapp](https://github.com/netbootxyz/webapp)
* Nginx for hosting local assets from the container
* tftp-hpa
* syslog for providing tftp activity logs

Services are managed in the container by [supervisord](http://supervisord.org/).
## Usage

The following snippets are examples of starting up the container. 
### docker-cli

```bash
docker run -d \
  --name=netbootxyz \
  -e MENU_VERSION=2.0.47 `# optional` \
  -p 3000:3000 `# sets webapp port` \
  -p 69:69/udp `# sets tftp port` \
  -p 8080:80 `# optional` \
  -v /local/path/to/config:/config `# optional` \
  -v /local/path/to/assets:/assets `# optional` \
  --restart unless-stopped \
  ghcr.io/netbootxyz/netbootxyz
```

#### Updating the image with docker-cli

```bash
docker pull ghcr.io/netbootxyz/netbootxyz   # pull the latest image down
docker stop netbootxyz                      # stop the existing container
docker rm netbootxyz                        # remove the image
docker run -d ...                           # previously ran start command
```

Start the container with the same parameters used above. If the same folders are used your settings will remain. If you want to start fresh, you can remove the paths and start over.

### docker-compose

```yaml
---
version: "2.1"
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz
    container_name: netbootxyz
    environment:
      - MENU_VERSION=2.0.47 # optional
    volumes:
      - /local/path/to/config:/config # optional
      - /local/path/to/assets:/assets # optional
    ports:
      - 3000:3000
      - 69:69/udp
      - 8080:80 #optional
    restart: unless-stopped
```

#### Updating the image with docker-compose

```bash
docker-compose pull netbootxyz     # pull the latest image down
docker-compose up -d netbootxyz    # start containers in the background
```

Once the container is started, the netboot.xyz web application can be accessed by the web configuration interface at http://localhost:3000 or via the specified port.

Downloaded web assets will be available at http://localhost:8080 or the specified port.  If you have specified the assets volume, the assets will be available at http://localhost:8080.

If you wish to start over from scratch, you can remove the local configuration folders and upon restart of the container, it will load the default configurations.

### Accessing the container services

Once the container is started, the netboot.xyz web application can be accessed by the web configuration interface at http://localhost:3000 or via the specified port.

Downloaded web assets will be available at http://localhost:8080 or the specified port.  If you have specified the assets volume, the assets will be available at http://localhost:8080.

If you wish to start over from scratch, you can remove the local configuration folders and upon restart of the container, it will load the default configurations.

## Parameters:

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 3000` | Web configuration interface. |
| `-p 69/udp` | TFTP Port. |
| `-p 80` | NGINX server for hosting assets. |
| `-e MENU_VERSION=2.0.47` | Specify a specific version of boot files you want to use from netboot.xyz (unset pulls latest) |
| `-v /config` | Storage for boot menu files and web application config |
| `-v /assets` | Storage for netboot.xyz bootable assets (live CDs and other files) |
