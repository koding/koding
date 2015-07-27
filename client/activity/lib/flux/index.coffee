module.exports =
  getters   : require './getters'
  actions   :
    message     : require './actions/message'
    thread      : require './actions/thread'
    channel     : require './actions/channel'
    suggestions : require './actions/suggestions'
  stores    : [
    require './stores/messagesstore'
    require './stores/channelsstore'
    require './stores/channelthreadsstore'
    require './stores/messagethreadssstore'
    require './stores/selectedchannelthreadidstore'
    require './stores/selectedmessagethreadidstore'
    require './stores/followedpublicchannelidsstore'
    require './stores/followedprivatechannelidsstore'
    require './stores/channelpopularmessageidsstore'
    require './stores/suggestions/suggestionsquerystore'
    require './stores/suggestions/suggestionsflagsstore'
    require './stores/suggestions/suggestionsstore'
  ]
