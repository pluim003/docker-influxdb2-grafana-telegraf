ARG TARGETOS
FROM arm64v8/debian:bullseye-slim as debian-arm64
LABEL maintainer="Dick Pluim <dockerhub@dickpluim.com>"

FROM debian-${TARGETARCH}

# FROM debian-${TARGETARCH}

# Default versions
ENV INFLUXDB_VERSION=2.8.0
ENV INFLUXCLI_VERSION=2.7.5
ENV TELEGRAF_VERSION=1.37.0
ENV GRAFANA_VERSION=12.3.0

ENV GF_DATABASE_TYPE=sqlite3

WORKDIR /root

# Problems with installing libc-bin

RUN rm /var/lib/dpkg/info/libc-bin.*
RUN apt-get clean
RUN apt-get update
RUN apt-get install libc-bin

# Clear previous sources
# RUN rm /var/lib/apt/lists/* -vf

    # Base dependencies
#    && apt-get -y update \
RUN apt-get -y install \
        apt-transport-https \
        apt-utils \
        ca-certificates \
#        curl \
        dialog \
#        git \
        htop \
        libfontconfig1 \
        lsof \
#        nano \
        procps \
        vim \
#        net-tools \
        wget \
#        gnupg \
        supervisor 

RUN apt-get -y install net-tools


# add Influx-repos
RUN wget -q https://repos.influxdata.com/influxdata-archive_compat.key
# RUN echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
# RUN echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list
# Install InfluxDB
#ARG TARGETARCH
#ARG ARCH=${TARGETARCH}
RUN \
   # if [ "${TARGETARCH}" = "arm" ]; then ARCH="armhf"; fi && \
   # if [ "$[TARGETARCH]" = "arm64" ]; then ARCH="arm64"; fi && \
  wget https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb2-${INFLUXDB_VERSION}_linux_arm64.tar.gz \
    && tar -xf influxdb2-${INFLUXDB_VERSION}_linux_arm64.tar.gz -C / && rm influxdb2-${INFLUXDB_VERSION}_linux_arm64.tar.gz \
    && cd /influxdb2-${INFLUXDB_VERSION} && cp -R * / && cd / && rm -rf influxdb2-${INFLUXDB_VERSION} \
    && groupadd -g 999 influxdb && useradd -ms /bin/bash -u 999 -g 999 influxdb 
# Install InfluxCLI
RUN \
  # influxdata-archive_compat.key GPG fingerprint:
  #     9D53 9D90 D332 8DC7 D6C8 D3B9 D8FF 8E1F 7DF8 B07E
 # sudo apt-get update && sudo apt-get install influxdb2-cli
  wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUXCLI_VERSION}-linux-arm64.tar.gz \
    && tar xvfz influxdb2-client-${INFLUXCLI_VERSION}-linux-arm64.tar.gz \ 
    && rm influxdb2-client-${INFLUXCLI_VERSION}-linux-arm64.tar.gz \
    && mv influx /usr/bin 
# Install Telegraf
RUN \
  wget https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz \
    && tar -xf telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz -C / && rm telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz \
    && cd /telegraf-${TELEGRAF_VERSION} && cp -R * / && cd / && rm -rf telegraf-${TELEGRAF_VERSION} \
    && groupadd -g 998 telegraf && useradd -ms /bin/bash -u 998 -g 998 telegraf 
 # Install Grafana
 RUN \
  apt-get install -y adduser libfontconfig1 musl \
    && wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_arm64.deb \
    && dpkg -i grafana_${GRAFANA_VERSION}_arm64.deb && rm grafana_${GRAFANA_VERSION}_arm64.deb \
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
