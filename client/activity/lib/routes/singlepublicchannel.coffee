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

PublicChannelNotificationSettingsRoute = require './publicchannelnotificationsettings'
SingleMessageRoute = require './singlemessage'
PublicChannelPopularMessages = require './publicchannelpopularmessages'

module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName'
    @childRoutes = [
      new PublicChannelNotificationSettingsRoute
      new PublicChannelPopularMessages
      new SingleMessageRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    messageActions.changeSelectedMessage null
    channelActions.setShowPopularMessagesFlag null

    { channelName } = nextState.params
    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> threadActions.changeSelectedThread null


shouldSetResultStateFlag = (routes) ->

  setResultStateFlagAsRecent = yes

  for route in routes
    path = route.path.toUpperCase()
    if ResultStates[path] and path isnt ResultStates.RECENT
      setResultStateFlagAsRecent = no

  return setResultStateFlagAsRecent


transitionToChannel = (channelName, done) ->

  { reactor } = kd.singletons

  isChannelOpened = no

  channel = channelByName channelName

  if channel
    isChannelOpened = reactor.evaluate ['OpenedChannelsStore', channel.id]

  # if we have an opened channel, switch to it immediately.
  if isChannelOpened
    threadActions.changeSelectedThread channel.id
    done()
  else
    channelActions.loadChannelByName(channelName).then ({channel}) ->
      threadActions.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id
      done()


