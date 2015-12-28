kd                  = require 'kd'
ActivityFlux        = require 'activity/flux'
ResultStates        = require 'activity/constants/resultStates'
ChannelThreadPane   = require 'activity/components/channelthreadpane'
transitionToChannel = require 'activity/util/transitionToChannel'
{ channelByName }   = ActivityFlux.getters

{
  thread  : threadActions,
  channel : channelActions } = ActivityFlux.actions

module.exports = class SinglePublicChannelPopularMessages

  constructor: ->

    @path = ':channelName/Liked'


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { channelName } = nextState.params

    channelActions.loadChannelByName(channelName).then ({channel}) ->
      channelActions.changeResultState channel._id, ResultStates.LIKED
      channelActions.loadPopularMessages(channel._id).then -> done()

    if channelName
      transitionToChannel channelName, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: -> actions.channel.changeResultState channel._id, ResultStates.RECENT

