actionTypes = require 'activity/flux/actions/actiontypes'
QueryStore  = require './chatinputquerystore'

###*
 * Store to contain channels query
###
module.exports = class ChatInputChannelsQueryStore extends QueryStore

  @getterPath = 'ChatInputChannelsQueryStore'

  initialize: ->

    actions =
      setQuery   : actionTypes.SET_CHAT_INPUT_CHANNELS_QUERY
      unsetQuery : actionTypes.UNSET_CHAT_INPUT_CHANNELS_QUERY

    @bindActions actions