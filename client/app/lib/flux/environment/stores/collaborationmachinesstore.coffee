KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class CollaborationMachinesStore extends KodingFluxStore

  @getterPath = 'CollaborationMachinesStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.COLLABORATION_INVITATION_REJECTED, @rejectInvitation


  load: (machines, { collaboration }) ->

    machines.withMutations (machines) ->
      collaboration.forEach ({ machine }) ->
        machines.set machine._id, machine._id


  rejectInvitation: (machines, id ) ->

    return machines  unless machines.has id

    machines.remove id
