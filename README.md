## 👋 Welcome to tftpd 🚀  

tftpd README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update tftpd
```
  
## Install and run container
  
```shell
mkdir -p "$HOME/.local/share/srv/docker/tftpd/rootfs"
git clone "https://github.com/dockermgr/tftpd" "$HOME/.local/share/CasjaysDev/dockermgr/tftpd"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/tftpd/rootfs/." "$HOME/.local/share/srv/docker/tftpd/rootfs/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-tftpd \
--hostname tftpd \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-tftpd/rootfs/data:/data:z" \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-tftpd/rootfs/config:/config:z" \
-p 80:80 \
casjaysdevdocker/tftpd:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/tftpd
    container_name: casjaysdevdocker-tftpd
    environment:
      - TZ=America/New_York
      - HOSTNAME=tftpd
    volumes:
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-tftpd/rootfs/data:/data:z"
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-tftpd/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/tftpd
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/tftpd" "$HOME/Projects/github/casjaysdevdocker/tftpd"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/tftpd"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
