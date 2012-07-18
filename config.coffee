kiteConfig =
  kiteMasterServer :
    # hostname    : "localhost"
    hostname    : "bs1.beta.system.aws.koding.com"
    port        : 4501
    reconnect   : 1000
  kfmjsBongoServer :
    hostname  : require('os').hostname()
    port      : 4500
  kites :
    terminaljs :
      name      : "terminaljs"
      hostname  : "cl2.beta.service.aws.koding.com"
    sharedHosting :
      name      : "sharedHosting"
      hostname  : "cl2.beta.service.aws.koding.com"
    databases :
      name      : "databases"
      hostname  : "*"
    fsWatcher :
      name      : "fsWatcherKitesTest"
      hostname  : "cl2.beta.service.aws.koding.com"
    testKite :
      name      : "testKite"
      hostname  : "localhost"


# this needs to live here, because process.pid needs to belong to kfmjs not to Cakefile.
# yes there is a way to move this over, but not now.

if require("os").platform() is 'linux'
  require("fs").writeFile "/var/run/node/koding.pid",process.pid,(err)->
    if err?
      console.log "[WARN] Can't write pid to /var/run/node/kfmjs.pid. monit can't watch this process."
