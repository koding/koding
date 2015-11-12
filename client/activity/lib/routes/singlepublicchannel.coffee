kd                = require 'kd'
ChannelThreadPane = require 'activity/components/channelthreadpane'
ActivityFlux      = require 'activity/flux'
getGroup          = require 'app/util/getGroup'
changeToChannel   = require 'activity/util/changeToChannel'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

NewPublicChannelRoute = require './newpublicchannel'
AllPublicChannelsRoute = require './allpublicchannels'
PublicChannelNotificationSettingsRoute = require './publicchannelnotificationsettings'

module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName(/:postId)'
    @childRoutes = [
      new NewPublicChannelRoute
      new AllPublicChannelsRoute
      new PublicChannelNotificationSettingsRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { channelName, postId } = nextState.params
    thread = kd.singletons.reactor.evaluate selectedChannelThread

    # if there is no channel name set on the route (/NewChannel, /Channels)
    unless channelName
      # if there is not a selected chat
      unless thread
        # set channel name to group channel name.
        channelName = getGroup().slug

    if channelName
      transitionToChannel channelName, postId, done
    else if not thread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: ->

    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null


transitionToChannel = (channelName, postId, done) ->

  successFn = ({ channel }) -> changeToChannel channel, postId, done
  channel = channelByName channelName

  if channel
    successFn { channel }
    messageActions.loadMessages channel.id
  else
    channelActions.loadChannelByName(channelName).then successFn


