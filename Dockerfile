ARG TARGETOS
FROM arm64v8/debian:bullseye-slim as debian-arm64
LABEL maintainer="Dick Pluim <dockerhub@dickpluim.com>"

FROM debian-${TARGETARCH}

# Default versions
ENV INFLUXDB_VERSION=2.7.1
ENV INFLUXCLI_VERSION=2.7.3
ENV TELEGRAF_VERSION=1.27.4
ENV GRAFANA_VERSION=10.1.0

ENV GF_DATABASE_TYPE=sqlite3

WORKDIR /root

# Clear previous sources
RUN rm /var/lib/apt/lists/* -vf \
    # Base dependencies
    && apt-get -y update \
    && apt-get -y install \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        dialog \
        git \
        htop \
        libfontconfig1 \
        lsof \
        nano \
        procps \
        vim \
        net-tools \
        wget \
        gnupg \
        supervisor 


# Install InfluxDB
ARG TARGETARCH
ARG ARCH=${TARGETARCH}
RUN \
   # if [ "${TARGETARCH}" = "arm" ]; then ARCH="armhf"; fi && \
   # if [ "$[TARGETARCH]" = "arm64" ]; then ARCH="arm64"; fi && \
  wget https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-${ARCH}.deb \
    && dpkg -i influxdb2-${INFLUXDB_VERSION}-${ARCH}.deb && rm influxdb2-${INFLUXDB_VERSION}-${ARCH}.deb \
# Install InfluxCLI
  && wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUXCLI_VERSION}-${ARCH}.deb \
    && dpkg -i influxdb2-client-${INFLUXCLI_VERSION}-${ARCH}.deb && rm influxdb2-client-${INFLUXCLI_VERSION}-${ARCH}.deb \
# Install Telegraf
 && wget  https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz \
     && tar -xf telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz -C / && rm telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz \
     && cd /telegraf-${TELEGRAF_VERSION} && cp -R * / && cd / && rm -rf telegraf-${TELEGRAF_VERSION} \
     && groupadd -g 998 telegraf && useradd -ms /bin/bash -u 998 -g 998 telegraf \
# Install Grafana
 && apt-get install -y adduser libfontconfig1 \
     && wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_${ARCH}.deb \
     && dpkg -i grafana_${GRAFANA_VERSION}_${ARCH}.deb && rm grafana_${GRAFANA_VERSION}_${ARCH}.deb \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Configure Supervisord
    && mkdir -p /var/log/supervisor

COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configure InfluxDB
RUN mkdir -p /home/influxdb
RUN mkdir -p /var/lib/influxdb
RUN mkdir -p /var/lib/influxdb2
RUN chown influxdb:influxdb /home/influxdb
RUN chown influxdb:influxdb /var/lib/influxdb
RUN chown influxdb:influxdb /var/lib/influxdb2
COPY influxdb2/influx-configs /etc/influxdb2/influx-configs
COPY influxdb2/config.toml /etc/influxdb2/config.toml
COPY influxdb2/config.toml /etc/influxdb/config.toml
COPY influxdb2/init.sh /etc/init.d/influxdb
RUN chmod 0755 /etc/init.d/influxdb

# Set up a configuration profile for InfluxDB
#RUN influx config create -n default \
# -u http://localhost:8086 \
# -o myorg \
# -t mySuP3rS3crt3tT0keN \
# -a

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini

# Configure Telegraf
COPY telegraf/init.sh /etc/init.d/telegraf
COPY telegraf/telegraf.conf /etc/telegraf/telegraf.conf
RUN chmod 0755 /etc/init.d/telegraf

LABEL org.opencontainers.image.authors="Dick Pluim" \
      org.opencontainers.image.title="pluim003/docker-influxdb2-grafana-telegraf" \
      org.opencontainers.image.description="Docker image with Influxdb2, Grafana and Telegraf" \
      org.opencontainers.image.url="https://github.com/pluim003/docker-influxdb2-grafana-telegraf" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/pluim003/docker-influxdb2-grafana-telegraf" \
      org.opencontainers.image.original_source="https://github.com/dcsg/docker-influxdb-grafana-telegraf"

CMD [ "/usr/bin/supervisord" ]
