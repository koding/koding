module.exports =
  getters   : require './getters'

  actions   :
    feed        : require './actions/feed'
    message     : require './actions/message'
    thread      : require './actions/thread'
    channel     : require './actions/channel'
    user        : require './actions/user'


  stores    : [
    require './stores/messagesstore'
    require './stores/channelsstore'
    require './stores/channelthreadsstore'
    require './stores/messagethreadssstore'
    require './stores/selectedchannelthreadidstore'
    require './stores/selectedmessagethreadidstore'
    require './stores/channelparticipantidsstore'
    require './stores/openedchannelsstore'
    require './stores/channelflagsstore'
    require './stores/messageflagsstore'
  ]

  register: (reactor) ->
    reactor.registerStores @stores

    realtimeActionCreators = require './actions/realtime/actioncreators'
    realtimeActionCreators.bindNotificationEvents()
    realtimeActionCreators.bindAppBadgeNotifiers()
