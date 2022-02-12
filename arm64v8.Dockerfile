FROM arm64v8/debian:bullseye-slim
LABEL maintainer="Dick Pluim <dockerhub@dickpluim.com>"

# Default versions
ENV INFLUXDB_VERSION=2.1.1
ENV INFLUXCLI_VERSION=2.2.0
ENV TELEGRAF_VERSION=1.21.3
ENV GRAFANA_VERSION=8.4.0~beta1

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
RUN wget https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-arm64.deb \
    && dpkg -i influxdb2-${INFLUXDB_VERSION}-arm64.deb && rm influxdb2-${INFLUXDB_VERSION}-arm64.deb 

# Install InfluxCLI
RUN wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUXCLI_VERSION}-arm64.deb \
    && dpkg -i influxdb2-client-${INFLUXCLI_VERSION}-arm64.deb && rm influxdb2-client-${INFLUXCLI_VERSION}-arm64.deb


# Install Telegraf
RUN wget  https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz \
     && tar -xf telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz -C / && rm telegraf-${TELEGRAF_VERSION}_linux_arm64.tar.gz \
     && cd /telegraf-${TELEGRAF_VERSION} && cp -R * / && cd / && rm -rf telegraf-${TELEGRAF_VERSION} \
     && groupadd -g 998 telegraf && useradd -ms /bin/bash -u 998 -g 998 telegraf 
     
# Install Grafana
RUN apt-get install -y adduser libfontconfig1 \
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
RUN chown influxdb:influxdb /home/influxdb
COPY influxdb/influxdb.conf /etc/influxdb/influxdb.conf
COPY influxdb/influxdb.conf /etc/influxdb2/influxdb.conf
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

CMD [ "/usr/bin/supervisord" ]
