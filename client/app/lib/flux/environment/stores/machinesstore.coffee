KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'
globals              = require 'globals'

module.exports = class MachinesStore extends KodingFluxStore

  @getterPath = 'MachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.MACHINE_UPDATED, @updateMachine
    @on actions.SET_MACHINE_ALWAYS_ON_BEGIN, @setAlwaysOnBegin
    @on actions.SET_MACHINE_ALWAYS_ON_SUCCESS, @setAlwaysOnSuccess
    @on actions.SET_MACHINE_ALWAYS_ON_FAIL, @setAlwaysOnFail
    @on actions.LOAD_MACHINE_SHARED_USERS, @loadSharedUsers
    @on actions.ADD_TEST_MACHINE, @set

    @on actions.INVITATION_ACCEPTED, @acceptInvitation
    @on actions.INVITATION_REJECTED, @rejectInvitation


  load: (machines, jmachines) ->

    machines.withMutations (machines) ->
      jmachines.forEach (machine) ->
        machine.hasOldOwner = machine.meta?.oldOwner?

        if machine.isMine()
          type = 'own'
        else if machine.isPermanent()
          type = 'shared'
        else
          type = 'collaboration'

        _machine = toImmutable machine
        _machine = _machine
          .set 'type', type
          .set 'owner', machine.getOwner()

        if m = machines.get machine._id
          if sharedUsers = m.get 'sharedUsers'
            _machine = _machine.set 'sharedUsers', sharedUsers

        machines.set machine._id, _machine


  updateMachine: (machines, { id, event, machine }) ->

    machines.withMutations (machines) ->
      if event
        { percentage, status } = event
        if status
          machine_ = machines.get(id).setIn [ 'status', 'state' ], status
        if percentage
          machine_ = (machine_ or machines.get(id)).set 'percentage', percentage

      if machine
        machine_ = toImmutable machine

      machines.set id, machine_


  acceptInvitation: (machines, id ) ->

    machine = machines.get id

    machine = machine.update 'users', (users) ->
      users.map (user) ->
        if user.get('id') is globals.userId
        then user.set 'approved', yes
        else user

    machines.set id, machine


  rejectInvitation: (machines, id) ->

    return machines  unless machines.has id

    return machines.remove id


  setAlwaysOnBegin: (machines, { id, state }) ->

    machines.withMutations (machines) ->
      machine = machines.get id
      machine = machine.setIn ['meta', '_alwaysOn'], machine.getIn ['meta', 'alwaysOn']
      machine = machine.setIn ['meta', 'alwaysOn'], state
      machines.set id, machine


  setAlwaysOnSuccess: (machines, { id }) ->

    machines.deleteIn [id, 'meta', '_alwaysOn']


  setAlwaysOnFail: (machines, { id }) ->

    machines.withMutations (machines) ->
      machine = machines.get id
      machine = machine.setIn ['meta', 'alwaysOn'], machine.getIn ['meta', '_alwaysOn']
      machine = machine.deleteIn ['meta', '_alwaysOn']
      machines.set id, machine

  loadSharedUsers: (machines, { id, users }) ->

    machines.setIn [id, 'sharedUsers'], toImmutable users

  set: (machines, machine) ->
    machines.set machine._id, toImmutable(machine).set('type', 'own')
