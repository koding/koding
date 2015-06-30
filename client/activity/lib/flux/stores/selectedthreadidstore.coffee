actionTypes     = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class SelectedThreadIdStore extends KodingFluxStore

  getInitialState: -> null

  initialize: ->

    @on actionTypes.CHANGE_SELECTED_THREAD, @handleChangeSelectedThread


  ###*
   * Handler for `CHANGE_SELECTED_THREAD` action.
   * It sets state's value as given given channelId.
   *
   * @param {null|string} currentState
   * @param {object} payload
   * @param {string} payload.channelId
   * @return {null|string} nextState
  ###
  handleChangeSelectedThread: (currentState, { channelId }) -> channelId


