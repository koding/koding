FROM mongo
MAINTAINER Christopher Thorn <chris@koding.com>

		

ADD dump/ /dump
RUN mkdir -p /root/data/db
# RUN cp -R /root/data/db/* /data/db/
RUN mongorestore --dbpath /root/data/db --drop --quiet --db koding /dump/koding
# RUN ln -sf /root/data/db /data/
RUN ls -lha /root/data/db
# RUN ls -lha /root/data/db