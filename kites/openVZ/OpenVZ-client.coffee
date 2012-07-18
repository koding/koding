openVzKites = require './openVzKites'
KiteServer  = require 'kiteserver'



config =
  name     : "OpenVZ"
  portRange     : [4501,4600]
  kiteApi       : openVzKites
  pidFile       :
    path      :  '/var/run/node/OpenVZ.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()