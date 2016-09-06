ActivityFlux = require 'activity/flux'

{
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

module.exports = class SinglePublicChannelSearch

  constructor: ->

    @path = 'Search/:query'


  onEnter: (nextState, replaceState, done) ->

    { channelName, query } = nextState.params

    messageActions.setChannelMessagesSearchQuery query

    channelActions.loadChannelByName(channelName).then ({channel}) ->
      messageActions.fetchMessagesByQuery channel.id, query

