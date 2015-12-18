KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class ActiveInvitationMachineIdStore extends KodingFluxStore

  @getterPath = 'ActiveInvitationMachineIdStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_ACTIVE_INVITATION_MACHINE_ID, @setMachineId


  setMachineId: (activeMachineId, { id, forceUpdate }) ->

    if forceUpdate or activeMachineId isnt id
      return id

    return null


