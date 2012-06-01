KiteServer    = require 'kiteserver'
nginxKites    = require './NginxKites'
fs            = require 'fs'
log4js        = require 'log4js'
log           = log4js.addAppender log4js.fileAppender("/var/log/node/NginX.log"), "[nginxApi-client]"
log           = log4js.getLogger('[nginxApi-client]')



config =
  name     : "nginx"
  portRange     : [4501,4600]
  kiteApi       : nginxKites
  pidFile       :
    path      :  '/var/run/node/NginX.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()