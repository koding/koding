kd                = require 'kd'
ChannelThreadPane = require 'activity/components/channelthreadpane'
ActivityFlux      = require 'activity/flux'
getGroup          = require 'app/util/getGroup'
changeToChannel   = require 'activity/util/changeToChannel'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread
  channelByName } = ActivityFlux.getters

module.exports = SingleChannelRoute =

  path: ':channelName(/:postId)'
  components:
    content: ChannelThreadPane
    modal: null

  onLeave: ->
    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null
  onEnter: (nextState, replaceState, done) ->
    { channelName, postId } = nextState.params

    thread = kd.singletons.reactor.evaluate selectedChannelThread

    unless channelName
      unless selectedChannelThread
        channelName = getGroup().slug

    if channelName
      transitionToChannel channelName, postId, done
    else if not selectedChannelThread
      threadActions.changeSelectedThread null
      done()


transitionToChannel = (channelName, postId, done) ->

  successFn = ({ channel }) -> changeToChannel channel, postId, done
  channel = channelByName channelName

  if channel
    successFn { channel }
    messageActions.loadMessages channel.id
  else
    channelActions.loadChannelByName(channelName).then successFn


