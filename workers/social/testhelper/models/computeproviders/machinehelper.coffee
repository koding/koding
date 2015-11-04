_          = require 'underscore'
hat        = require 'hat'
{ daisy }  = require 'bongo'
{ expect } = require 'chai'

JUser      = require '../../../lib/social/models/user/index'
JMachine   = require '../../../lib/social/models/computeproviders/machine'

{ reviveClient } = require '../../../../social/lib/social/models/computeproviders/computeutils'


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


createUserAndMachine = (userInfo, callback) ->

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

    -> callback null, { machine, user, account }

  ]

  daisy queue


fetchMachinesByUsername = (username, callback) ->

  JMachine.fetchByUsername username, (err, machines) ->
    expect(err).to.not.exist
    expect(machines).to.be.an 'array'
    expect(machines.length).to.be.above 0
    callback machines



createMachine = (client, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  machineParams    = {}

  queue = [

    ->
      generateMachineParams client, opts, (err, data) ->
        return callback err  if err
        machineParams = data
        queue.next()

    ->
      JMachine.create machineParams, (err, machine) ->
        callback err, { machine }

  ]

  daisy queue



module.exports = {
  createMachine
  createUserAndMachine
  generateMachineParams
  fetchMachinesByUsername
  generateMachineParamsByAccount
}

