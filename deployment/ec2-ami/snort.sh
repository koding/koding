#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:$PATH

yum --assumeyes install --enablerepo=epel \
    libpcap libpcap-devel \
    libdnet libdnet-devel \
    bison bison-devel

pushd /usr/local/src

SNORT_DOWNLOADS="https://www.snort.org/downloads"

DAQ_VERSION="2.0.6"
SNORT_VERSION="2.9.8.2"

curl --silent --location $SNORT_DOWNLOADS/snort/daq-$DAQ_VERSION.tar.gz | \
  tar --extract --gunzip --file -
curl --silent --location $SNORT_DOWNLOADS/snort/snort-$SNORT_VERSION.tar.gz | \
  tar --extract --gunzip --file -

pushd daq-$DAQ_VERSION
./configure
make
make install
popd

echo PATH=$PATH

pushd snort-$SNORT_VERSION
./configure --enable-gre \
            --enable-mpls \
            --enable-targetbased \
            --enable-ppm \
            --enable-perfprofiling \
            --enable-active-response \
            --enable-normalizer \
            --enable-reload \
            --enable-react \
            --enable-flexresp3 \
            --enable-sourcefire
make
make install
popd 2

mkdir -p /etc/snort \
         /etc/snort/rules \
         /var/log/snort

touch /etc/snort/rules/black_list.rules \
      /etc/snort/rules/white_list.rules

curl --silent --location $SNORT_DOWNLOADS/community/community-rules.tar.gz | \
  tar --extract --gunzip --directory /etc/snort/ --file -

SNORT_OINKCODE="2056866cf2e8ca256fd75d1dd2171d973aff9f85"
SNORT_RULES_SNAPSHOT_VERSION="2980"
SNORT_REGISTERED_RULES_URL="https://www.snort.org/rules/snortrules-snapshot-$SNORT_RULES_SNAPSHOT_VERSION.tar.gz"

curl --silent --location $SNORT_REGISTERED_RULES_URL?oinkcode=$SNORT_OINKCODE | \
  tar --extract --gunzip --directory /etc/snort/ --file -

mv --no-clobber etc/* $PWD
rmdir etc

groupadd snort

useradd snort \
        --home-dir /var/log/snort \
        --shell /sbin/nologin \
        --comment SNORT_IDS \
        --gid snort

chown --recursive snort:snort \
      /etc/snort \
      /etc/init.d/snort \
      /etc/sysconfig/snort \
      /var/log/snort

chkconfig --add snort
