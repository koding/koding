FROM mongo
MAINTAINER Christopher Thorn <chris@koding.com>


# ADD . /mongo-dump

# WORKDIR /mongo-dump

# RUN tar jxvf /mongo-dump/default-db-dump.tar.bz2
# RUN ls -lha /mongo-dump

# RUN /usr/local/bin/mongod --replSet dev --fork --logpath /var/log/mongodb.log --dbpath /data/db --smallfiles --nojournal && mongorestore -hlocalhost -dkoding /mongo-dump/dump/koding

# RUN rm -rf /mongo-dump/dump

EXPOSE 27017
ENTRYPOINT ["mongod"]
