KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actiontypes'

module.exports = class ActiveInvitationMachineIdStore extends KodingFluxStore

  @getterPath = 'ActiveInvitationMachineIdStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_ACTIVE_INVITATION_MACHINE_ID, @setMachineId


  setMachineId: (activeMachineId, { id, forceUpdate }) ->

    return id  if forceUpdate or activeMachineId isnt id
    return null
