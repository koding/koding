actions    = require 'activity/flux/actions/actiontypes'
QueryStore = require './chatinputquerystore'

###*
 * Store to contain channels query
###
module.exports = class ChatInputChannelsQueryStore extends QueryStore

  @getterPath = 'ChatInputChannelsQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_CHANNELS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_CHANNELS_QUERY