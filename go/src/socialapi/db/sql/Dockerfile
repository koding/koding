FROM ubuntu:14.04
MAINTAINER Cihangir Savas <cihangir@koding.com>

# set the time to UTC
RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
RUN date

RUN apt-get update
RUN apt-get install -y postgresql postgresql-contrib
USER postgres
RUN sed -i "s/#timezone =.*/timezone = 'UTC'/" /etc/postgresql/9.3/main/postgresql.conf
RUN sed -i "s/#listen_addresses =.*/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf
# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

ADD definition              /definition
ADD notification_definition /notification_definition
ADD sitemap_definition      /sitemap_definition
ADD payment_definition      /payment_definition
ADD integration_definition  /integration_definition
ADD kontrol 	            /kontrol


USER root

RUN service postgresql start && \
    /definition/init.sh && \
    su postgres -c /definition/create.sh

EXPOSE 5432

RUN ls -lha /usr/lib/postgresql/9.3/bin/

USER postgres
# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
