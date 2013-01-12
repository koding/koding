{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

AuthWorker = require './authworker'

configFile = argv.c

KONFIG = require('koding-config-manager').load("main.#{configFile}")

authWorker = new AuthWorker koding, KONFIG.authWorker.authResourceName
authWorker.connect()
