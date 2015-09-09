_         = require 'underscore'
hat       = require 'hat'
{ daisy } = require 'bongo'

JUser     = require '../../lib/social/models/user/index'
JMachine  = require '../../lib/social/models/computeproviders/machine'

{ reviveClient } = require '../../../social/lib/social/models/computeproviders/computeutils'


generateMachineParams = (client, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback

  reviveClient client, (err, data) ->
    data.provider = 'koding'
    data          = _.extend data, opts
    callback err, data


generateMachineParamsByAccount = (account, callback) ->

  _client =
    connection :
      delegate : account
    context    :
      group    : 'koding'

  generateMachineParams _client, (err, data) ->
    return callback err  if err
    callback null, data


createUserAndMachine = (userInfo, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback

  user          = {}
  machine       = {}
  account       = {}
  machineParams = {}

  queue = [

    ->
      JUser.createUser userInfo, (err, user_, account_) ->
        return callback err  if err
        [user, account] = [user_, account_]
        queue.next()

    ->
      generateMachineParamsByAccount account, (err, data) ->
        return callback err  if err
        machineParams = data
        queue.next()

    ->
      JMachine.create machineParams, (err, machine_) ->
        return callback err  if err
        machine = machine_
        queue.next()

    -> callback null, machine, user, account

  ]

  daisy queue


module.exports = {
  createUserAndMachine
  generateMachineParams
  generateMachineParamsByAccount
}

