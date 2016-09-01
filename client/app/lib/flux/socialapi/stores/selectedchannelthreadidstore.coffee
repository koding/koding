actions         = require '../actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'


module.exports = class SelectedChannelThreadIdStore extends KodingFluxStore

  @getterPath = 'SelectedChannelThreadIdStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SELECTED_CHANNEL_THREAD, @setSelectedChannelId


  ###*
   * Handler for `CHANGE_SELECTED_THREAD` action.
   * It sets state's value as given given channelId.
   *
   * @param {null|string} currentState
   * @param {object} payload
   * @param {string} payload.channelId
   * @return {null|string} nextState
  ###
  setSelectedChannelId: (currentState, { channelId }) -> channelId
