klient deployment notes
=======================

* Configure

Configure an AWS profile for uploading files to S3:

```bash
~ $ aws --profile koding-klient configure
aws --profile XD configure
AWS Access Key ID [None]: ***
AWS Secret Access Key [None]: ***
Default region name [None]: us-east-1
Default output format [None]: json
```

* Build

```bash
klient $ ./build.sh
usage: build.sh CHANNEL [VERSION]
```

```bash
klient $ ./build.sh development
# builing klient: version 215, channel development, os Darwin
~/src/github.com/koding/koding ~/src/github.com/koding/koding/go/src/koding/klient
koding/klient
# builing klient: version 215, channel development, os Linux
/opt/koding /opt/koding
koding/klient
building klient
preparing build folders
preparing install folders
starting build process
.  .  .  .  .  .  .

success 'klient_0.1.215_development_amd64.deb' is ready. Some helpful commands for you:

  show deb content   : dpkg -c klient_0.1.215_development_amd64.deb
  show basic info    : dpkg -f klient_0.1.215_development_amd64.deb
  install to machine : dpkg -i klient_0.1.215_development_amd64.deb

Package: klient
Version: 0.1.215
Architecture: amd64
Maintainer: Koding Developers <hello@koding.com>
Installed-Size: 10361
Section: devel
Priority: extra
Homepage: https://koding.com
Description: klient Kite
/opt/koding
~/src/github.com/koding/koding/go/src/koding/klient
# built klient successfully: version 215, channel development, os Darwin
```

* Deploy

```bash
klient $ ./deploy.sh
usage: deploy.sh CHANNEL VERSION [AWS PROFILE] [S3 BUCKET]
```

```bash
klient $ ./deploy.sh development 215
# uploading files to s3://koding-klient/development/215/
upload: ../../../../klient-0.1.215.gz to s3://koding-klient/development/215/klient-0.1.215.gz
upload: ../../../../klient-0.1.215.darwin_amd64.gz to s3://koding-klient/development/215/klient-0.1.215.darwin_amd64.gz
upload: ../../../../klient_0.1.215_development_amd64.deb to s3://koding-klient/development/215/klient_0.1.215_development_amd64.deb
# uploading files to s3://koding-klient/development/latest/
delete: s3://koding-klient/development/latest/klient-0.1.214.darwin_amd64.gz
delete: s3://koding-klient/development/latest/klient-0.1.214.gz
delete: s3://koding-klient/development/latest/klient.deb
delete: s3://koding-klient/development/latest/klient.darwin_amd64.gz
delete: s3://koding-klient/development/latest/klient.gz
delete: s3://koding-klient/development/latest/klient_0.1.214_development_amd64.deb
copy: s3://koding-klient/development/215/klient-0.1.215.gz to s3://koding-klient/development/latest/klient-0.1.215.gz
copy: s3://koding-klient/development/215/klient-0.1.215.darwin_amd64.gz to s3://koding-klient/development/latest/klient-0.1.215.darwin_amd64.gz
copy: s3://koding-klient/development/215/klient_0.1.215_development_amd64.deb to s3://koding-klient/development/latest/klient_0.1.215_development_amd64.deb
copy: s3://koding-klient/development/latest/klient-0.1.215.gz to s3://koding-klient/development/latest/klient.gz
copy: s3://koding-klient/development/latest/klient-0.1.215.darwin_amd64.gz to s3://koding-klient/development/latest/klient.darwin_amd64.gz
copy: s3://koding-klient/development/latest/klient_0.1.215_development_amd64.deb to s3://koding-klient/development/latest/klient.deb
# updating latest-version.txt to 215
delete: s3://koding-klient/development/latest-version.txt
upload: ./latest-version.txt to s3://koding-klient/development/latest-version.txt
```

:tada:
