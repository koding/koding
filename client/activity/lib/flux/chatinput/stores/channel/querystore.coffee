actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to contain channels query
###
module.exports = class ChatInputChannelsQueryStore extends BaseQueryStore

  @getterPath = 'ChatInputChannelsQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_CHANNELS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_CHANNELS_QUERY
