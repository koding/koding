kd                        = require 'kd'
ActivityFlux              = require 'activity/flux'
NotificationSettingsModal = require 'activity/components/publicchannelnotificationsettingsmodal'
NotificationSettingsFlux  = require 'activity/flux/channelnotificationsettings'
transitionToChannel       = require 'activity/util/transitionToChannel'
ChannelThreadPane         = require 'activity/components/channelthreadpane'

{
  thread  : threadActions,
  channel : channelActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

module.exports = class PublicChannelNotificationSettingsRoute

  constructor: ->

    @path = ':channelName/NotificationSettings'

  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: NotificationSettingsModal


  onEnter: (nextState, replaceState, done) ->

    channel = channelByName nextState.params.channelName

    { params, routes, location } = nextState
    { channelName } = params

    channelActions.loadChannelByName(channelName).then ({channel}) ->
      NotificationSettingsFlux.actions.channel.load(channel.id).then -> done()

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


onLeave: -> threadActions.changeSelectedThread null

