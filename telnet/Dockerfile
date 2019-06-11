FROM centos:7

RUN yum install -y xinetd && yum install -y telnet-server
COPY telnet /etc/xinetd.d/telnet
COPY docker-entrypoint.sh /
RUN chmod 777 docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
