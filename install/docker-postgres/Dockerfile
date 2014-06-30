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

# RUN service postgresql restart

# RUN ln -s /usr/lib/postgresql/9.3/bin/postgres /usr/bin/
# RUN sudo -u postgres

ADD definition /definition
ADD notification_sql /notification_sql

# create folders for postgres data
# RUN mkdir -p /var/lib/postgresql/data/tablespace/social
# RUN mkdir -p /var/lib/postgresql/data/tablespace/socialbig
# # give ownership to postgres
# RUN whoami

# RUN chown -R postgres:postgres /var/lib/postgresql/data


RUN service postgresql start && bash /definition/create.sh

# EXPOSE 5432
RUN service postgresql start && psql --command "\list"

RUN ls -lha /usr/lib/postgresql/9.3/bin/
# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
