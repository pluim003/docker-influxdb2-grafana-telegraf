# Docker Image with InfluxDB 2.x, Grafana and Telegraf

The purpose of this docker image is to provide an image for arm64v8 (Raspberry Pi).

| Description  | Value             |
|--------------|-------------------|
| OS           | arm64v8           |
| InfluxDB     | 2.6.1             |
| InfluxCli    | 2.6.1             |
| Grafana      | 9.3.6             |
| Telegraf     | 1.25.0            |

## Note

This is a newly created repository with as base 'influxdb-grafana-telegraf', a fork of the repository created by Daniel Gomes. 
As I have only a Raspberry Pi I can only test the image on arm64v8 (and arm32v7). 
As InfluxDB 2.x is slightly different, so far I haven't had this working. Especially when using the upgrade-function with this image. For the upgrade-function I use the regular influxdb-image and after that I should have a 2.x-installation to continue, besides the working InfluxDB 1.x-installation. For the 2.x-installation during testing I will use different ports.

## Quick Start

#### Raspberry Pi (arm64v8)

Start the container by running the following command:

```sh
docker run -d \
  --name influxdb2-grafana \
  --restart unless-stopped \
  -p 3003:3003 \
  -p 8086:8086 \
  -v /path/for/influxdb_data:/var/lib/influxdb \
  -v /path/for/influxdb_log:/var/log/influxdb \
  -v /path/for/grafana_data:/var/lib/grafana \
  -v /path/for/grafana_log:/var/log/grafana \
  -v /path/for/telegraf_log:/var/log/telegraf \ 
  -e "GF_SECURITY_ADMIN_USER=<YOU_USERNAME_HERE>" \
  -e "GF_SECURITY_ADMIN_PASSWORD=<YOU_PASSWORD_HERE>" \
  -e "TZ=<YOUR_LOCAL_TIMEZONE_HERE>"
  pluim003/influxdb2-grafana-telegraf:latest
```

Note: I added a bunch of extra volumes as I like to be able to view stuff directly on my Raspberry Pi. Feel free to modify the docker-run-command to your needs.

To stop the container launch:

```sh
docker stop influxdb2-grafana
```

To start the container again launch:

```sh
docker start influxdb2-grafana
```

To backup your Docker-volumes you can use the following script:

```sh
#!/bin/bash

CONTAINER=influxdb2-grafana
RUNNING_CONTAINER=$(docker container ls -q --filter name=${CONTAINER}*)
CONTAINER_VOL1=/var/lib/grafana
CONTAINER_VOL2=/var/lib/influxdb
CONTAINER_VOL3=
BACKUP_DIR=<YOUR_BACKUP_DIRECTORY_HERE>/${CONTAINER}
TODAY=$(date +"%Y%m%d_%H%M")

if [ ! -d "${BACKUP_DIR}" ] ; then
   mkdir ${BACKUP_DIR}
fi

docker pause ${RUNNING_CONTAINER}

docker run --rm  --volumes-from ${CONTAINER} -v ${BACKUP_DIR}:/backup busybox tar cvpfz /backup/${CONTAINER}cfg_${TODAY}.tgz ${CONTAINER_VOL1} ${CONTAINER_VOL2} ${CONTAINER_VOL3}

docker unpause ${RUNNING_CONTAINER}

# check and delete backupfiles older dan 7 dagen

find ${BACKUP_DIR}/${CONTAINER}cfg*  -mtime +7 -exec ls -ltr  {} \;
find ${BACKUP_DIR}/${CONTAINER}cfg*.tgz -mtime +7 -exec ls -ltr {} \;
find ${BACKUP_DIR}/${CONTAINER}cfg*  -mtime +7 -exec ls -ltr  {} \;
```

## Mapped Ports

| Host  | Container | Service  |
|-------|-----------|----------|
| 3003  | 3003      | grafana  |
| 8086  | 8086      | influxdb |

## SSH

```sh
docker exec -it influxdb2-grafana bash
```

## Grafana

Open <http://localhost:3003>

```
Username: <User defined in Environment Variable>
Password: <Password defined in Environment Variable>
```

### Add data source on Grafana

1. Using the wizard click on `Add data source`
2. Choose a `name` for the source and flag it as `Default`
3. Choose `InfluxDB` as `type`
4. Fill `URL` with `http://localhost:8086`
5. Choose `Server (Default)` as `access`
6. Fill the database and the remaining fields and click `Save & Test`.

Basic auth and credentials must be left unflagged. Proxy is not required.

Now you are ready to add your first dashboard and launch some queries on a database.

### InfluxDB Shell (CLI)

```sh
docker exec -it influxdb2-grafana influx
```
