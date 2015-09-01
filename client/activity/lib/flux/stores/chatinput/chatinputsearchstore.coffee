immutable       = require 'immutable'
actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'


###*
 * Store to handle chat input search items
###
module.exports = class ChatInputSearchStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.CHAT_INPUT_SEARCH_SUCCESS, @handleSuccess
    @on actions.CHAT_INPUT_SEARCH_FAIL,    @handleReset
    @on actions.CHAT_INPUT_SEARCH_RESET,   @handleReset


  ###*
   * Handler for CHAT_INPUT_SEARCH_SUCCESS action.
   * It replaces items list with successfully fetched items
   * for a given action initiator
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @param {array} payload.items
   * @return {Immutable.Map} nextState
  ###
  handleSuccess: (currentState, { initiatorId, items }) ->

    currentState.set initiatorId, toImmutable items


  ###*
   * Handler for CHAT_INPUT_SEARCH_RESET and CHAT_INPUT_SEARCH_FAIL actions.
   * It deletes items for a given action initiator
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @return {Immutable.Map} nextState
  ###
  handleReset: (currentState, { initiatorId }) ->

    currentState.delete initiatorId

