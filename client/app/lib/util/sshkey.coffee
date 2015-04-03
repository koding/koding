kd = require 'kd'
Promise = require 'bluebird'
KDObject = kd.Object


module.exports = class SshKey extends KDObject

  constructor: (options) ->

    super
    { @key } = options


  deployTo: (machines, callback) ->

    return  unless machines

    promises = []
    request = keys: [ @key ]

    machines.forEach (machine) ->
      kite = machine.getBaseKite()
      p = kite.init().then ->
        kite.sshKeysAdd request
      promises.push p

    Promise
      .any promises
      .then ->
        callback()
      .catch (errs) ->
      	callback errs[0]
