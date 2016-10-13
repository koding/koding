FROM mongo:2.4
MAINTAINER Sonmez Kartal <sonmez@koding.com>

ADD default-db-dump.tar.bz2 /opt/dump/
RUN mkdir --parents /opt/db && \
    mongorestore --dbpath /opt/db /opt/dump/ && \
    chown --recursive mongodb:mongodb /opt/db && \
    rm --force --recursive /opt/dump

CMD ["--dbpath", "/opt/db", "--smallfiles", "--nojournal"]
