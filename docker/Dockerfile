FROM centos:7

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y sudo gcc make git vim \
    iproute \
    ethtool \
    redhat-lsb-core \
    initscripts \
    perl-Class-Accessor \
    perl-Jcode \
    perl-Carp \
    perl-Storable \
    perl-parent \
    perl-File-Spec-Native \
    perl-Scalar-List-Utils \
    perl-PathTools \
    perl-Pod-Simple \
    perl-Encode \
    perl-podlators \
    perl-ExtUtils-Install \
    perl-ExtUtils-MakeMaker \
    perl-Module-CoreList \
    perl-Data-Dumper \
    dstat \
    python-setuptools \
 && easy_install speedtest-cli && rm -rf /var/cache/yum/* && yum clean all

RUN mkdir -p /app
WORKDIR /app

RUN git clone https://github.com/matsumotory/qos-control /app
RUN cp /app/etc/rc.d/init.d/qos.init /etc/rc.d/init.d/

COPY set-ether.sh /app/set-ether.sh
COPY bootstrap.sh /bootstrap.sh
CMD ["/bootstrap.sh"]
