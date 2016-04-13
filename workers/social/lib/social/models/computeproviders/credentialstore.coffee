hat       = require 'hat'
jraphical = require 'jraphical'

{ argv }  = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class CredentialStore

  JCredentialData  = require './credentialdata'


  storeOnMongo = (data, callback) ->

    credData = new JCredentialData data
    credData.save (err) ->
      callback err, data.identifier


  @create = (client, data, callback) ->

    { meta, originId, identifier } = data
    identifier ?= hat()
    data = { meta, originId, identifier }

    storeOnMongo data, callback
