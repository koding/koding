KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class StacksStore extends KodingFluxStore

  @getterPath = 'StacksStore'

  _convertMachinesToIds = (jStack) ->
    stack      = toImmutable jStack
    machines   = stack.get('machines').toJS()
    machineIds = machines.map (m) -> m._id
    stack      = stack.set 'machines', machineIds
    return stack


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_USER_STACKS_SUCCESS, @load
    @on actions.STACK_UPDATED, @updateStack
    @on actions.REMOVE_STACK, @removeStack


  load: (stacks, jstacks) ->

    stacks.withMutations (stacks) ->
      jstacks.forEach (jstack) ->
        stacks.set jstack._id, _convertMachinesToIds jstack


  updateStack: (stacks, stack) ->

    stacks.withMutations (stacks) ->
      stacks.set stack._id, _convertMachinesToIds stack


  removeStack: (stacks, id) ->

    stacks.withMutations (stacks) ->
      stacks.remove id
