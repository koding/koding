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

      notifyByUsernames options.target, 'SharedMachineInvitation', { uid, group: client?.context?.group }
      notifyOwner client, options
      callback()


  @kick = secure (client, uid, target, callback) ->

    asUser  = no
    options = { target, asUser }
    setUsers client, uid, options, (err) ->
      return callback err  if err

      notifyOwner client, options
      callback()


  notifyOwner = (client, options) ->

    { nickname } = client.connection.delegate.profile
    options.group = client?.context?.group
    notifyByUsernames [ nickname ], 'MachineShareListUpdated', options


  setUsers = (client, uid, options, callback) ->

    options.permanent = yes
    JMachine.shareByUId client, uid, options, callback
