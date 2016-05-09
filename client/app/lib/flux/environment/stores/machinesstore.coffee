KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class MachinesStore extends KodingFluxStore

  @getterPath = 'MachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.MACHINE_UPDATED, @updateMachine
    @on actions.INVITATION_ACCEPTED, @acceptInvitation
    @on actions.SET_MACHINE_ALWAYS_ON, @setAlwaysOn


  load: (machines, { own, shared, collaboration }) ->

    envData = own.concat shared.concat collaboration

    machines.withMutations (machines) ->
      envData.forEach ({ machine, workspaces }) ->
        machine.hasOldOwner = machine.meta?.oldOwner?
        machines.set machine._id, toImmutable machine


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

    machines.setIn [id, 'isApproved'], yes


  setAlwaysOn: (machines, { id, state }) ->

    machines.setIn [id, 'meta', 'alwaysOn'], state
