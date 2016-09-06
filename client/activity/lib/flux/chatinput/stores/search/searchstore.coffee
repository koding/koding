immutable       = require 'immutable'
actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to handle chat input search items
###
module.exports = class ChatInputSearchStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.CHAT_INPUT_SEARCH_SUCCESS, @handleSuccessSearch
    @on actions.CHAT_INPUT_SEARCH_FAIL,    @handleResetSearch
    @on actions.CHAT_INPUT_SEARCH_RESET,   @handleResetSearch


  ###*
   * Handler for CHAT_INPUT_SEARCH_SUCCESS action.
   * It replaces items list with successfully fetched items
   * for a given stateId
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {array} payload.items
   * @return {Immutable.Map} nextState
  ###
  handleSuccessSearch: (currentState, { stateId, items }) ->

    currentState.set stateId, toImmutable items


  ###*
   * Handler for CHAT_INPUT_SEARCH_RESET and CHAT_INPUT_SEARCH_FAIL actions.
   * It deletes items for a given stateId
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {Immutable.Map} nextState
  ###
  handleResetSearch: (currentState, { stateId }) ->

    currentState.delete stateId
