kd           = require 'kd'
ActivityFlux = require 'activity/flux'

module.exports = class SinglePublicChannelRecentMessages

  constructor: ->

    @path = ':channelName/Recent'


  onEnter: (nextState) ->

    { channelName } = nextState.params

    return kd.singletons.router.handleRoute "/Channels/#{channelName}"


  onLeave: -> ActivityFlux.actions.thread.changeSelectedThread null
