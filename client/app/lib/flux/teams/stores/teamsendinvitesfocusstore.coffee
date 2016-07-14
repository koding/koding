KodingFluxStore = require 'app/flux/base/store'
actions = require '../actiontypes'

module.exports = class TeamSendInvitesFocusStore extends KodingFluxStore

  @getterPath = 'TeamSendInvitesFocusStore'

  getInitialState: -> no

  initialize: ->

    @on actions.FOCUS_SEND_INVITES_SECTION, @changeState

  changeState: (oldState, newState) -> newState
