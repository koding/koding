kd                       = require 'kd'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'
ActivityFlux             = require 'activity/flux'
getGroup                 = require 'app/util/getGroup'
changeToChannel          = require 'activity/util/changeToChannel'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters


module.exports =
  path: ':privateChannelId(/:postId)'
  components:
    content: PrivateMessageThreadPane
    modal: null

  onEnter: (nextState, replaceState, done) ->
    { privateChannelId, postId } = nextState.params

    thread = kd.singletons.reactor.evaluate selectedChannelThread

    unless privateChannelId
      unless thread
        botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'
        privateChannelId = botChannel.id

    if privateChannelId
      transitionToChannel privateChannelId, postId, done
    else if not thread
      threadActions.changeSelectedThread null
      done()


  onLeave: ->

    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null


transitionToChannel = (channelId, postId, done) ->

  successFn = ({ channel }) -> changeToChannel channel, postId, done

  channel = kd.singletons.reactor.evaluateToJS ['ChannelsStore', channelId]

  if channel
    successFn { channel }
    messageActions.loadMessages channel.id
  else
    channelActions.loadChannel(channelId).then successFn


