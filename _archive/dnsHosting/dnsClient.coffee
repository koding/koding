sharedHostingKites = require './dnsKites'
KiteServer         = require 'kiteserver'


config =
  name     : "dns"
  portRange     : [4501,4600]
  kiteApi       : dnsKites
  pidFile       :
    path      :  '/var/run/node/dnsApi.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()