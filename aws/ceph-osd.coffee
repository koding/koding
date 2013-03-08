aws = require 'koding-aws'

buildTemplate = (callback) ->
  aws.getNextCephName 'osd', (err, nextName) ->
    if err
      callback err, ''
      return

    template =
      type          : 'm1.medium'
      ami           : 'ami-de0d9eb7'
      keyName       : 'koding'
      securityGroups: ['sg-3942b156']
      subnet        : 'subnet-f5d0199f'
      tags          : [
        Key         : 'Name'
        Value       : "ceph-osd-#{nextName}-test"
      ,
        Key         : 'ceph_type'
        Value       : 'osd'
      ,
        Key         : 'ceph_id'
        Value       : nextName
      ]
      devices       : [
        DeviceName  : '/dev/xvdf'
        Ebs         :
          VolumeSize         : 50
          DeleteOnTermination: yes
          VolumeType         : 'standard'
      ]
      userData      : """
                      #!/bin/bash
                      /bin/hostname #{nextName}.ceph.system.aws.koding.com
                      echo "127.0.0.1 $(hostname)" | tee /etc/hosts -a
                      route del default gw 10.0.0.1
                      route add default gw 10.0.0.63
                      set -e -x
                      LOGFILE="/var/log/user-data-out.log"
                      mkdir -p /etc/chef
                      cat > /root/.s3cfg << "EOF"
                      [default]
                      access_key = AKIAJO74E23N33AFRGAQ
                      bucket_location = US
                      cloudfront_host = cloudfront.amazonaws.com
                      cloudfront_resource = /2010-07-15/distribution
                      default_mime_type = binary/octet-stream
                      delete_removed = False
                      dry_run = False
                      encoding = UTF-8
                      encrypt = False
                      follow_symlinks = False
                      force = False
                      get_continue = False
                      guess_mime_type = True
                      host_base = s3.amazonaws.com
                      host_bucket = %(bucket)s.s3.amazonaws.com
                      human_readable_sizes = False
                      list_md5 = False
                      log_target_prefix = 
                      preserve_attrs = True
                      progress_meter = True
                      proxy_host = 
                      proxy_port = 0
                      recursive = False
                      recv_chunk = 4096
                      reduced_redundancy = False
                      secret_key = kpKvRUGGa8drtLIzLPtZnoVi82WnRia85kCMT2W7
                      send_chunk = 4096
                      simpledb_host = sdb.amazonaws.com
                      skip_existing = False
                      socket_timeout = 10
                      urlencoding_mode = normal
                      use_https = True
                      verbosity = WARNING
                      EOF
                      export DEBIAN_FRONTEND=noninteractive
                      echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
                      apt-get update >> $LOGFILE
                      apt-get -y --force-yes install opscode-keyring >> $LOGFILE
                      apt-get -y upgrade >> $LOGFILE
                      apt-get -y install s3cmd chef --force-yes >> $LOGFILE
                      /usr/bin/s3cmd --config /root/.s3cfg get s3://koding-vagrant-Lti5bj61mVnfMkhX/chef-conf/chris-test-validator.pem /etc/chef/chris-test-validator.pem --force
                      /usr/bin/s3cmd --config /root/.s3cfg get s3://chef-conf/chrisTest-osd.rb /etc/chef/client.rb --force
                      echo "{ \"run_list\": [ \"role[ceph-osd]\" ] }" > /etc/chef/client.json

                      service chef-client restart
                      """

    callback no, template

module.exports = 
  buildTemplate: buildTemplate
