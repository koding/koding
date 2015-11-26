KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class MachinesStore extends KodingFluxStore

  @getterPath = 'MachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load


  load: (machines, { own, shared, collaboration }) ->

    envData = own.concat shared.concat collaboration

    machines.withMutations (machines) ->
      envData.forEach ({ machine, workspaces }) ->
        machines.set machine._id, toImmutable machine
