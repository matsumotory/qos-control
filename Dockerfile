FROM centos:7

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y sudo git vim iproute ethtool redhat-lsb-core perl-Class-Accessor perl-Jcode

RUN mkdir -p /app
WORKDIR /app

RUN git clone https://github.com/matsumotory/qos-control /app
RUN cp /app/etc/rc.d/init.d/qos.init /etc/rc.d/init.d/

CMD /bin/bash
