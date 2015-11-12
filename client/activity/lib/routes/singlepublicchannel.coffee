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
SingleMessageRoute = require './singlemessage'

module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName'
    @childRoutes = [
      new NewPublicChannelRoute
      new AllPublicChannelsRoute
      new PublicChannelNotificationSettingsRoute
      new SingleMessageRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    messageActions.changeSelectedMessage null

    { channelName } = nextState.params
    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    # if there is no channel name set on the route (/NewChannel, /Channels)
    unless channelName
      # if there is not a selected chat
      unless selectedThread
        # set channel name to group channel name.
        channelName = getGroup().slug

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> threadActions.changeSelectedThread null


transitionToChannel = (channelName, done) ->

  successFn = ({ channel }) ->
    threadActions.changeSelectedThread channel.id
    channelActions.loadParticipants channel.id
    done()

  channel = channelByName channelName

  if channel
    successFn { channel }
    messageActions.loadMessages channel.id
  else
    channelActions.loadChannelByName(channelName).then successFn


