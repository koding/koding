FROM mongo
MAINTAINER Christopher Thorn <chris@koding.com>

ADD dump/ /dump
RUN mkdir -p /root/data/db

# INSERTING DEFAULT DATASET TO MONGODB

RUN mongorestore --dbpath /root/data/db --drop --quiet --db koding /dump/koding

# UPDATING MONGO AS PER SOCIAL API REQUIREMENTS (@cihangir)

# RUN mongod --fork --logpath /var/log/mongodb.log --dbpath /root/data/db --smallfiles --nojournal && mongo localhost/koding --eval='db.jAccounts.update({},{$unset:{socialApiId:0}},{multi:true}); db.jGroups.update({},{$unset:{socialApiChannelId:0}},{multi:true});'

EXPOSE 27017
ENTRYPOINT ["mongod"]
