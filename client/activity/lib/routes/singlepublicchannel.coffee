kd                                     = require 'kd'
ChannelThreadPane                      = require 'activity/components/channelthreadpane'
ActivityFlux                           = require 'activity/flux'
transitionToChannel                    = require 'activity/util/transitionToChannel'
SingleMessageRoute                     = require './singlemessage'
ResultStates                           = require 'activity/constants/resultStates'
PublicChannelNotificationSettingsRoute = require 'activity/routes/publicchannelnotificationsettings'

{
  thread  : threadActions,
  message : messageActions,
  channel : channelActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName'
    @childRoutes = [
      new PublicChannelNotificationSettingsRoute
      new SingleMessageRoute
    ]

  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    messageActions.changeSelectedMessage null

    { channelName, postId } = nextState.params
    { pathname } = nextState.location

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    channel = channelByName channelName

    if channelName
      transitionToChannel channelName, (err, channel) ->
        channelActions.changeResultState channel._id, ResultStates.RECENT
        done()
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> threadActions.changeSelectedThread null
