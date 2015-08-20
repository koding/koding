immutable       = require 'immutable'
actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'


###*
 * Store to handle chat input search items
###
module.exports = class ChatInputSearchStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchStore'

  getInitialState: -> immutable.List()


  initialize: ->

    @on actions.CHAT_INPUT_SEARCH_SUCCESS, @handleSuccess
    @on actions.CHAT_INPUT_SEARCH_FAIL,    @handleReset
    @on actions.CHAT_INPUT_SEARCH_RESET,   @handleReset


  ###*
   * Handler for CHAT_INPUT_SEARCH_SUCCESS action.
   * It replaces current items list with successfully fetched items
   *
   * @param {Immutable.List} currentItems
   * @param {object} payload
   * @param {array} payload.items
   * @return {Immutable.List} new items
  ###
  handleSuccess: (currentItems, { items }) -> toImmutable items


  ###*
   * Handler for CHAT_INPUT_SEARCH_RESET and CHAT_INPUT_SEARCH_FAIL actions.
   * It sets current items to empty immutable list
   *
   * @param {Immutable.List} items
   * @return {Immutable.List} empty immutable list
  ###
  handleReset: (items) -> immutable.List()
