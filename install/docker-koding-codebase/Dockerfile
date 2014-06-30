FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

USER root
ENV HOME /root
ENV DOCKER yes
ENV KODING_PROJECT_ROOT /opt/koding
ENV KODING_BUILD_DATA_PATH /root/BUILD_DATA
ENV BLD /root/BUILD_DATA


RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

WORKDIR /opt

ADD .ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

RUN git clone git@github.com:koding/koding.git

WORKDIR /opt/koding
