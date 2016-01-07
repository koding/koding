kd                = require 'kd'
ActivityFlux      = require 'activity/flux'
getGroup          = require 'app/util/getGroup'
changeToChannel   = require 'activity/util/changeToChannel'
ChannelThreadPane = require 'activity/components/channelthreadpane'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

SingleMessageRoute = require './singlemessage'

module.exports = class SinglePrivateChannelRoute

  constructor: ->

    @path = ':privateChannelId'
    @childRoutes = [
      new SingleMessageRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { privateChannelId, postId } = nextState.params

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    if privateChannelId
      transitionToChannel privateChannelId, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: ->

    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null


transitionToChannel = (channelId, done) ->

  { reactor } = kd.singletons

  isChannelOpened = reactor.evaluateToJS ['OpenedChannelsStore', channelId]

  # if we already have a channel in the channel store, just switch to it.
  if isChannelOpened
    threadActions.changeSelectedThread channelId
    done()
  # if not, load necessary things then switch to it.
  else
    channelActions.loadChannel(channelId).then ({ channel }) ->
      threadActions.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id
      done()
