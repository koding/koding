{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

AuthWorker = require './authworker'

{authWorker} = require argv.c

authWorker = new AuthWorker koding, authWorker.authResourceName
authWorker.connect()


console.log {authWorker}
