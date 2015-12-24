kd                  = require 'kd'
ChannelThreadPane   = require 'activity/components/channelthreadpane'
ActivityFlux        = require 'activity/flux'
transitionToChannel = require 'activity/util/transitionToChannel'
SingleMessageRoute  = require './singlemessage'

{
  thread  : threadActions,
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
    { pathname } = location

    unless nextState.params.postId
      return kd.singletons.router.handleRoute "#{pathname}/Recent"

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

