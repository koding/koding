assert  = require 'assert'
mongo   = require 'mongodb'
{argv}  = require 'optimist'

assert argv.c?
assert argv.h?
assert argv.r?

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

exports.run = (fn) ->
  mongo.MongoClient.connect "mongodb://#{KONFIG.mongo}", (err, db)->
    throw err  if err?

    fn db