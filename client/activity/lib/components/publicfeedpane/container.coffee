kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
immutable       = require 'immutable'
ResultState     = require 'activity/constants/resultStates'
ActivityFlux    = require 'activity/flux'


module.exports = class PublicFeedPaneContainer extends React.Component

  @propTypes =
    thread          : React.PropTypes.instanceOf immutable.Map
    popularChannels : React.PropTypes.instanceOf immutable.Map

  @defaultProps =
    thread          : immutable.Map()
    popularChannels : immutable.Map()


  channel: (keyPath...) -> @props.thread?.getIn ['channel'].concat keyPath


  onLoadMore: ->

    return  unless (messages = @props.thread.get 'messages').size

    switch @props.thread.getIn ['flags', 'resultListState']
      when ResultState.LIKED
        from = messages.last().get 'createdAt'
        ActivityFlux.actions.channel.loadPopularMessages @channel('id'), { from }
      when ResultState.RECENT
        from = messages.first().get 'createdAt'
        ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  onThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @onLoadMore()


  render: ->

    <View
      thread          = { @props.thread }
      onLoadMore      = { @bound 'onLoadMore' }
      popularChannels = { @props.popularChannels }/>