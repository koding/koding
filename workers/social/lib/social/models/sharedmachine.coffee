bongo = require 'bongo'

{secure} = bongo

JMachine = require './computeproviders/machine'


module.exports = class SharedMachine extends bongo.Base

  @share()

  setUsers = (client, uid, options, callback) ->

    options.permanent = yes
    JMachine.shareByUId client, uid, options, callback
