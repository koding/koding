{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

AuthWorker = require './authworker'

configFile = argv.c
KONFIG = require('koding-config-manager').load("main.#{configFile}")

processMonitor = (require 'processes-monitor').start
  name : "Auth Worker #{process.pid}"
  stats_id: "worker.auth." + process.pid
  interval : 30000
  librato: librato

authWorker = new AuthWorker koding, KONFIG.authWorker.authResourceName
authWorker.connect()
