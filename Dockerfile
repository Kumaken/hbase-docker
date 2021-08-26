# HBase in Docker
#
# Version 0.5

# http://docs.docker.io/en/latest/use/builder/

FROM ubuntu:bionic
MAINTAINER Dave Beckett <dave@dajobe.org>

COPY *.sh /build/

ENV HBASE_VERSION 2.2.4

RUN /build/prepare-hbase.sh && \
    cd /opt/hbase && /build/build-hbase.sh \
    cd / && /build/cleanup-hbase.sh && rm -rf /build

VOLUME /data

ADD ./hbase-site.xml /opt/hbase/conf/hbase-site.xml

ADD ./zoo.cfg /opt/hbase/conf/zoo.cfg

ADD ./replace-hostname /opt/replace-hostname

ADD ./hbase-server /opt/hbase-server

# REST API
EXPOSE 8080
# REST Web UI at :8085/rest.jsp
EXPOSE 8085
# Thrift API
EXPOSE 9090
# Thrift Web UI at :9095/thrift.jsp
EXPOSE 9095
# HBase's Embedded zookeeper cluster
EXPOSE 2181
# HBase Master web UI at :16010/master-status;  ZK at :16010/zk.jsp
EXPOSE 16010


# PREPARE CRON
# 1. install lsof to kill previously used ports when restarting
RUN apt-get update
RUN apt-get install lsof
# 2. cron job:
RUN apt-get update && apt-get -y install cron
COPY thrift-cron /etc/cron.d/thrift-cron
COPY restart-thrift /etc/cron.d/restart-thrift
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/thrift-cron
RUN chmod 0744 /etc/cron.d/restart-thrift
# Apply cron job
RUN crontab /etc/cron.d/thrift-cron

CMD /opt/hbase-server
