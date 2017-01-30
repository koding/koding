FROM koding/base
MAINTAINER Sonmez Kartal <sonmez@koding.com>

RUN apt-get update && \
    apt-get install --yes \
            mongodb-server \
            postgresql postgresql-contrib \
            rabbitmq-server \
            redis-server

RUN rabbitmq-plugins enable rabbitmq_management

USER postgres
RUN sed -i "s/#listen_addresses =.*/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
USER root

RUN cd /opt && git clone https://github.com/koding/koding.git

WORKDIR /opt/koding

RUN service postgresql start && \
    go/src/socialapi/db/sql/definition/create.sh && \
    service postgresql stop

RUN npm install --unsafe-perm && \
    echo master > VERSION && \
    ./configure --host localhost --hostname localhost --publicPort 80 && \
    go/build.sh && \
    service postgresql start && ./run migrate up && service postgresql stop && \
    make -C client dist && \
    rm -rf generated


ADD docker-entrypoint /opt/koding/docker-entrypoint
ADD entrypoint.sh /opt/koding/entrypoint.sh
ADD wait.sh /opt/koding/wait.sh

EXPOSE 80

ENTRYPOINT ["/opt/koding/docker-entrypoint"]
