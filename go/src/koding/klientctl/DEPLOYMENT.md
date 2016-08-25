klient deployment notes
=======================

* Configure

Configure an AWS profile for uploading files to S3:

```bash
~ $ aws --profile koding-klient configure
AWS Access Key ID [None]: ***
AWS Secret Access Key [None]: ***
Default region name [None]: us-east-1
Default output format [None]: json
```

Export segment.io key:

```bash
~ $ export KD_SEGMENTIO_KEY=***
```

* Build

```bash
klientctl $ ./build.sh
usage: build.sh CHANNEL [VERSION]
```

```bash
klientctl $ ./build.sh development
# builing kd: version 103, channel development, os Darwin
~/src/github.com/koding/koding ~/src/github.com/koding/koding/go/src/koding/klientctl
koding/klientctl
# builing kd: version 103, channel development, os Linux
/opt/koding /opt/koding
koding/klientctl
/opt/koding
~/src/github.com/koding/koding/go/src/koding/klientctl
# built kd successfully: version 103, channel development, os Darwin
```

* Deploy

```bash
klientctl $ ./deploy.sh
usage: deploy.sh CHANNEL VERSION [AWS PROFILE] [S3 BUCKET]
```

```bash
klientctl $ ./deploy.sh development 103
~/src/github.com/koding/koding ~/src/github.com/koding/koding/go/src/koding/klientctl
# uploading files to s3://koding-kd/development/103/
upload: ./kd-0.1.103.linux_amd64.gz to s3://koding-kd/development/103/kd-0.1.103.linux_amd64.gz
upload: ./kd-0.1.103.darwin_amd64.gz to s3://koding-kd/development/103/kd-0.1.103.darwin_amd64.gz
delete: s3://koding-kd/development/install-kd.sh
upload: ./install-kd.sh to s3://koding-kd/development/install-kd.sh
# updating latest-version.txt to 103
delete: s3://koding-kd/development/latest-version.txt
upload: ./latest-version.txt to s3://koding-kd/development/latest-version.txt
~/src/github.com/koding/koding/go/src/koding/klientctl
```

:tada:
