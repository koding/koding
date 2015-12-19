kd                = require 'kd'
ActivityFlux      = require 'activity/flux'
ChannelThreadPane = require 'activity/components/channelthreadpane'

{ channelByName } = ActivityFlux.getters
{ actions } = ActivityFlux

module.exports = class PublicChannelPopularMessages

  constructor: ->

    @path = 'Liked'


  getComponents: (state, callback) ->

    callback null,
      content: ChannelThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    actions.message.changeSelectedMessage null

    { channelName } = nextState.params

    channel = channelByName channelName

    actions.channel.setShowPopularMessagesFlag yes
    actions.channel.loadPopularMessages channel._id
      .then -> done()


  onLeave: ->

    actions.thread.changeSelectedThread null
    actions.channel.setShowPopularMessagesFlag null

