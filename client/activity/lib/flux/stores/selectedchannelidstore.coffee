actionTypes     = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class SelectedChannelStore extends KodingFluxStore

  getInitialState: -> null

  initialize: ->

    @on actionTypes.CHANGE_SELECTED_CHANNEL, @handleChangeSelectedChannel


  ###*
   * Handler for `CHANGE_SELECTED_CHANNEL` action.
   * It sets state's value as given given channelId.
   *
   * @param {null|string} currentState
   * @param {object} payload
   * @param {string} payload.channelId
   * @return {null|string} nextState
  ###
  handleChangeSelectedChannel: (currentState, { channelId }) -> channelId

