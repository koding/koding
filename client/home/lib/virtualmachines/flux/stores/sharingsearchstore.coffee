immutable       = require 'immutable'
actions         = require '../actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class VirtualMachinesSharingSearchStore extends KodingFluxStore

  @getterPath = 'VirtualMachinesSharingSearchStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, @setSearchItems
    @on actions.RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, @resetSearchItems


  setSearchItems: (currentState, { machineId, items }) ->

    currentState.set machineId, toImmutable items


  resetSearchItems: (currentState, { machineId }) ->

    currentState.delete machineId
