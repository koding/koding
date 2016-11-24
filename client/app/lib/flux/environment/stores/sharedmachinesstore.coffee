KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
actions         = require '../actiontypes'

module.exports = class SharedMachinesStore extends KodingFluxStore

  @getterPath = 'SharedMachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.SHARED_VM_INVITATION_REJECTED, @rejectInvitation


  load: (machines, { shared }) ->

    machines.withMutations (machines) ->
      shared.forEach ({ machine }) ->
        machines.set machine.uid, machine._id


  rejectInvitation: (machines, id) ->

    return machines  unless machines.has id

    machines.remove id
