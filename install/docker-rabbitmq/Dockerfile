FROM ubuntu:14.04
MAINTAINER Christopher Thorn <chris@koding.com>

RUN apt-get install -y rabbitmq-server=3.2.4-1

ADD plugins/rabbit_presence_exchange-3.2.3-20140220.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.2.4/plugins/
RUN rabbitmq-plugins enable rabbit_presence_exchange
RUN rabbitmq-plugins enable rabbitmq_management
RUN service rabbitmq-server restart
EXPOSE 15672:15672
EXPOSE 5672:5672
ENTRYPOINT ["rabbitmq-server"]
