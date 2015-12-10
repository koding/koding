kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
FeedList       = require 'activity/components/feedlist'
immutable      = require 'immutable'
FeedPane       = require 'activity/components/feedpane'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
ActivityFlux   = require 'activity/flux'

module.exports = class PublicFeedPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()


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

    ActivityFlux.actions.message.loadMessages @channel('id'),
      from: messages.first().get 'createdAt'


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
      key={@props.thread.get 'channelId'}
      thread={@props.thread}
      onLoadMore={@bound 'onLoadMore'}
    />

