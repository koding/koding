KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
actions         = require '../actiontypes'


module.exports = class ConnectedManagedMachineStore extends KodingFluxStore

  @getterPath = 'ConnectedManagedMachineStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, @add
    @on actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, @remove


  add: (connectedMachines, { info, id }) ->

    connectedMachines.withMutations (connectedMachines) ->
      connectedMachines.set id, info


  remove: (connectedMachines, { id }) ->

    connectedMachines.remove id
