ChatInputModule = require './chatinput'

module.exports =
  getters   : require './getters'

  actions   :
    message         : require './actions/message'
    thread          : require './actions/thread'
    channel         : require './actions/channel'
    suggestions     : require './actions/suggestions'
    user            : require './actions/user'
    chatInputSearch : require './actions/chatinputsearch'

  stores    : [
    require './stores/messagesstore'
    require './stores/channelsstore'
    require './stores/channelthreadsstore'
    require './stores/messagethreadssstore'
    require './stores/selectedchannelthreadidstore'
    require './stores/selectedmessagethreadidstore'
    require './stores/followedpublicchannelidsstore'
    require './stores/followedprivatechannelidsstore'
    require './stores/popularchannelidsstore'
    require './stores/channelparticipantidsstore'
    require './stores/channelpopularmessageidsstore'
    require './stores/suggestions/suggestionsquerystore'
    require './stores/suggestions/suggestionsflagsstore'
    require './stores/suggestions/suggestionsstore'
    require './stores/suggestions/suggestionsselectedindexstore'
    require './stores/messagelikerssstore'
    require './stores/channelflagsstore'
    require './stores/messageflagsstore'
    require './stores/chatinput/chatinputchannelsselectedindexstore'
    require './stores/chatinput/chatinputchannelsquerystore'
    require './stores/chatinput/chatinputchannelsvisibilitystore'
    require './stores/chatinput/chatinputusersselectedindexstore'
    require './stores/chatinput/chatinputusersquerystore'
    require './stores/chatinput/chatinputusersvisibilitystore'
    require './stores/chatinput/chatinputsearchselectedindexstore'
    require './stores/chatinput/chatinputsearchquerystore'
    require './stores/chatinput/chatinputsearchvisibilitystore'
    require './stores/chatinput/chatinputsearchstore'
  ]
  # module stores
  .concat ChatInputModule.stores

