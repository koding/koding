#! /bin/bash
set -o errexit

DEST=/usr/local/Cellar/neo4j/community-1.9.1-unix/libexec/plugins/graphity
mkdir -p $DEST

cp lib/gson-2.2.4.jar $DEST

cd bin
jar -cvf $DEST/graphity.jar *

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_25.jdk/Contents/Home/
/usr/local/bin/neo4j restart