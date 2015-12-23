ActivityFlux      = require 'activity/flux'
ResultStates      = require 'activity/util/resultStates'
ChannelThreadPane = require 'activity/components/channelthreadpane'
{ channelByName } = ActivityFlux.getters
{ channel : channelActions } = ActivityFlux.actions

module.exports = class PublicChannelPopularMessages

  constructor: ->

    @path = 'Liked'


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { channelName } = nextState.params
    channel = channelByName channelName

    channelActions.setChannelResultStateFlag channel._id, ResultStates.LIKED
    channelActions.loadPopularMessages(channel._id).then -> done()


  onLeave: ->

    actions.channel.setChannelResultStateFlag channel._id, ResultStates.RECENT

