kd = require 'kd'
Promise = require 'bluebird'
Machine = require 'app/providers/machine'


module.exports = class SshKey

  constructor: (options) ->

    { @key } = options


  deployTo: (machines, callback) ->

    return  unless machines

    promises = []
    request = keys: [ @key ]

    machines.forEach (machine) ->
      return  unless machine.status.state is Machine.State.Running

      kite = machine.getBaseKite()
      p = kite.init().then ->
        kite.sshKeysAdd request
      promises.push p

    Promise
      .all promises
      .nodeify callback
