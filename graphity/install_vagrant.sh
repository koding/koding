#! /bin/bash
set -o errexit

DEST=/var/lib/neo4j/plugins/graphity
mkdir -p $DEST
chown -R neo4j:adm $DEST/
cp lib/gson-2.2.4.jar $DEST

jar -cvf $DEST/graphity.jar *

export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/
service neo4j-service restart
