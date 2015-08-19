immutable       = require 'immutable'
actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'


module.exports = class ChatInputSearchStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchStore'

  getInitialState: -> immutable.List()


  initialize: ->

    @on actions.CHAT_INPUT_SEARCH_SUCCESS, @handleSuccess
    @on actions.CHAT_INPUT_SEARCH_FAIL,    @handleReset
    @on actions.CHAT_INPUT_SEARCH_RESET,   @handleReset


  handleSuccess: (results, { items }) -> toImmutable items


  handleReset: (results) -> immutable.List()