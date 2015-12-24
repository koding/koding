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


module.exports = class SingleChannelRoute

  constructor: ->

    @path = ':channelName'
    @childRoutes = [
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

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> threadActions.changeSelectedThread null

