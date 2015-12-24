kd                  = require 'kd'
ChannelThreadPane   = require 'activity/components/channelthreadpane'
ActivityFlux        = require 'activity/flux'
getGroup            = require 'app/util/getGroup'
changeToChannel     = require 'activity/util/changeToChannel'
ResultStates        = require 'activity/constants/resultStates'
transitionToChannel = require 'activity/util/transitionToChannel'

{
  thread  : threadActions,
  channel : channelActions } = ActivityFlux.actions

{ selectedChannelThread } = ActivityFlux.getters

module.exports = class SinglePublicChannelRecentMessages

  constructor: ->

    @path = ':channelName/Recent'


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { channelName } = nextState.params

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    channelActions.loadChannelByName(channelName).then ({channel}) ->
      channelActions.changeResultState channel._id, ResultStates.RECENT

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> threadActions.changeSelectedThread null

