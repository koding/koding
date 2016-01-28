KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class OwnMachinesStore extends KodingFluxStore

  @getterPath = 'OwnMachinesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load


  load: (machines, { own }) ->

    machines.withMutations (machines) ->
      own.forEach ({ machine }) ->
        machines.set machine._id, machine._id
