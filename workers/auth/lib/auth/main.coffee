process.title    = 'koding-authworker'
koding           = require './bongo'
koding.connect()

KONFIG         = require 'koding-config-manager'

AuthWorker     = require './authworker'

{ authWorker } = KONFIG

processMonitor = (require 'processes-monitor').start
  name : "Auth Worker #{process.pid}"
  stats_id: 'worker.auth.' + process.pid
  interval : 30000

authWorker = new AuthWorker koding, {
  authExchange    : KONFIG.authWorker.authExchange
  authAllExchange : KONFIG.authWorker.authAllExchange
}

options =
  port  : KONFIG.authWorker.port

# expose healthcheck and version handlers
require('../../../runartifactserver') 'authworker', options

authWorker.connect()
