Broker = require 'broker'
Feeder = require './feeder'

dbUrl = "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
# JAccount = require '../../social/lib/social/models/account'
# JAccount.setClient dbUrl

broker = new Broker
  host    : 'localhost'
  login   : 'guest'
  password: 'guest'
  vhost   : '/'

feeder = new Feeder
  mq        : broker
  mongo     : dbUrl

accounts = {}

broker.ready ->
  broker.on 'event-JAccount', "AccountAuthenticated", (account) ->
    return if accounts[account.profile.nickname]?
    accounts[account.profile.nickname] = account
# JAccount.on "AccountAuthenticated", (account) ->
    feeder.handlerFollowAction account
    #feeder.handleAccount account