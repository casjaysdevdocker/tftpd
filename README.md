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
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/tftpd/tftpd/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/tftpd/rootfs"
git clone "https://github.com/dockermgr/tftpd" "$HOME/.local/share/CasjaysDev/dockermgr/tftpd"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/tftpd/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-tftpd-latest \
--hostname tftpd \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
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
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/tftpd/tftpd/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/tftpd/tftpd/latest/rootfs/config:/config:z"
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
