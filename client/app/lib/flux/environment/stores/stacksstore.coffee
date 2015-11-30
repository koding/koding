KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class StacksStore extends KodingFluxStore

  @getterPath = 'StacksStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_STACKS_SUCCESS, @load


  load: (stacks, jstacks) ->

    stacks.withMutations (stacks) ->
      jstacks.forEach (stack) ->
        stack.machines = stack.machines.map (m) -> m._id
        stacks.set stack._id, toImmutable stack
