FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

USER root
ENV HOME /root
ENV DOCKER yes
ENV KODING_PROJECT_ROOT "/opt/koding"
ENV BLD /opt/koding/install/BUILD_DATA

RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

WORKDIR /opt

ADD BUILD_DATA/.ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

RUN git clone git@git.sj.koding.com:koding/koding.git
ADD BUILD_DATA /opt/koding/install/BUILD_DATA

WORKDIR /opt/koding



# RUN cat $BLD/BUILD_CONFIG.json
# ENTRYPOINT ["/opt/koding/run"]
# RUN `cat $BLD/BUILD_HOSTNAME` >/etc/hostname
# RUN hostname `cat $BLD/BUILD_HOSTNAME`
