kd                = require 'kd'
ChannelThreadPane = require 'activity/components/channelthreadpane'
ActivityFlux      = require 'activity/flux'
getGroup          = require 'app/util/getGroup'
changeToChannel   = require 'activity/util/changeToChannel'
ResultStates      = require 'activity/util/resultStates'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

PublicChannelNotificationSettingsRoute = require './publicchannelnotificationsettings'
SingleMessageRoute = require './singlemessage'
SinglePublicChannelPopularMessages = require './singlepublicchannelpopularmessages'

module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName'
    @childRoutes = [
      new PublicChannelNotificationSettingsRoute
      new SinglePublicChannelPopularMessages
      new SingleMessageRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    messageActions.changeSelectedMessage null

    { params, routes, location } = nextState
    { channelName } = params

    if location.pathname is "/Channels/#{channelName}"
      route = "/Channels/#{channelName}/Recent"
      return kd.singletons.router.handleRoute route

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    channel = channelByName channelName

    channelActions.loadChannelByName(channelName).then ({channel}) ->
      if shouldSetResultStateFlag routes
        channelActions.setChannelResultStateFlag channel.id, ResultStates.RECENT

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


