nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{projectRoot, webserver, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"

module.exports = new Bongo {
  mongo: mongoReplSet or mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
}