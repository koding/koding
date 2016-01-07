kd            = require 'kd'
React         = require 'kd-react'
ReactDOM      = require 'react-dom'
immutable     = require 'immutable'
FeedPane      = require './feedpane'
ActivityFlux  = require 'activity/flux'
ScrollerMixin = require 'app/components/scroller/scrollermixin'
ResultState   = require 'activity/constants/resultStates'

module.exports = class PublicFeedPane extends React.Component

  @defaultProps =
    thread          : immutable.Map()
    messages        : immutable.List()
    popularChannels : immutable.List()


  channel: (keyPath...) -> @props.thread?.getIn ['channel'].concat keyPath

  getMessages: ->

    messages = @props.thread.get 'messages'

    return immutable.Map()  unless messages

    messages.sort (a, b) ->
      if a.get('createdAt') > b.get('createdAt') then -1
      else if a.get('createdAt') < b.get('createdAt') then return 1
      else 0


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

    return null  unless @props.thread

    <FeedPane
      ref='feedPane'
      popularChannels={@props.popularChannels}
      key={@props.thread.get 'channelId'}
      thread={@props.thread}
      onLoadMore={@bound 'onLoadMore'}
    />
