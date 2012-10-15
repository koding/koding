Broker = require 'broker'
Feeder = require './feeder'

feeder = new Feeder
  mq        : new Broker
    host    : 'localhost'
    login   : 'guest'
    password: 'guest'
    vhost   : '/'

JAccount.on "AccountAuthenticated", (account) ->
  feeder.handleAccount account