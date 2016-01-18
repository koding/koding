KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class SharedMachineListItemsStore extends KodingFluxStore

  @getterPath = 'SharedMachineListItemsStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.MACHINE_LIST_ITEM_CREATED, @setMachineListItem
    @on actions.MACHINE_LIST_ITEM_DELETED, @unsetMachineListItem


  setMachineListItem: (listItems, { id, machineListItem }) ->

    listItems.set id, machineListItem


  unsetMachineListItem: (listItems, { id, machineListItem }) ->

    listItems.remove id


