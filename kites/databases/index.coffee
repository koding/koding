api = require './api'
config = require './config'

api.run config






###
databasesKites = require './databasesKites'
KiteServer         = require 'kiteserver'



config =
  name     : "databases"
  portRange     : [4505,4600]
  kiteApi       : databasesKites
  pidFile       :
    path      :  '/var/run/node/Databases.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()
