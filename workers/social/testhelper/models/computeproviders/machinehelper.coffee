{ _
  async
  expect } = require '../../../testhelper/index'

JUser      = require '../../../lib/social/models/user/index'
JMachine   = require '../../../lib/social/models/computeproviders/machine'

{ reviveClient } = require '../../../../social/lib/social/models/computeproviders/computeutils'


generateMachineParams = (client, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback

  reviveClient client, (err, data) ->
    data.provider = 'aws'
    data          = _.extend data, opts
    callback err, data


generateMachineParamsByAccount = (account, callback) ->

  client =
    connection :
      delegate : account
    context    :
      group    : 'koding'

  generateMachineParams client, (err, data) ->
    return callback err  if err
    callback null, data


createUserAndMachine = (userInfo, callback) ->

  user          = {}
  machine       = {}
  account       = {}
  machineParams = {}

  queue = [

    (next) ->
      JUser.createUser userInfo, (err, user_, account_) ->
        [user, account] = [user_, account_]
        next err

    (next) ->
      generateMachineParamsByAccount account, (err, data) ->
        machineParams = data
        next err

    (next) ->
      JMachine.create machineParams, (err, machine_) ->
        machine = machine_
        next err

  ]

  async.series queue, (err) -> callback err, { machine, user, account }


fetchMachinesByUsername = (username, callback) ->

  JMachine.fetchByUsername username, (err, machines) ->
    expect(err).to.not.exist
    expect(machines).to.be.an 'array'
    expect(machines.length).to.be.above 0
    callback machines


createMachine = (client, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  machineParams    = {}
  machine          = null

  queue = [

    (next) ->
      generateMachineParams client, opts, (err, data) ->
        machineParams = data
        next err

    (next) ->
      JMachine.create machineParams, (err, machine_) ->
        machine = machine_
        next err

  ]

  async.series queue, (err) -> callback err, { machine }



module.exports = {
  createMachine
  createUserAndMachine
  generateMachineParams
  fetchMachinesByUsername
  generateMachineParamsByAccount
}
