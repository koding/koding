KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class SharedMachinesStore extends KodingFluxStore

  @getterPath = 'SharedMachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load


  load: (machines, { shared }) ->

    machines.withMutations (machines) ->
      shared.forEach ({ machine }) ->
        machines.set machine._id, machine._id
