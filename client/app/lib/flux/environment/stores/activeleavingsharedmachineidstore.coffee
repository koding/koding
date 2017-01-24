KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actiontypes'

module.exports = class ActiveLeavingSharedMachineIdStore extends KodingFluxStore

  @getterPath = 'ActiveLeavingSharedMachineIdStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, @setMachineId

  setMachineId: (activeWidgetId, { id }) -> return id
