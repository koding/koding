bongo = require 'bongo'

{ secure, signature } = bongo

{ notifyByUsernames } = require './notify'

JMachine = require './computeproviders/machine'


module.exports = class SharedMachine extends bongo.Base

  @share()

  @set
    sharedMethods  :
      static       :
        add        : (signature String, Object, Function)
        kick       : (signature String, Object, Function)


  @add = secure (client, uid, target, callback) ->

    asUser  = yes
    options = { target, asUser }
    setUsers client, uid, options, (err) ->
      return callback err  if err

      { nickname } = client.connection.delegate.profile

      notifyByUsernames options.target, 'SharedMachineInvitation', { uid }
      notifyByUsernames [ nickname ], 'MachineShareListUpdated', options
      callback()


  @kick = secure (client, uid, target, callback) ->

    asUser  = no
    options = { target, asUser }
    setUsers client, uid, options, callback


  setUsers = (client, uid, options, callback) ->

    options.permanent = yes
    JMachine.shareByUId client, uid, options, callback
