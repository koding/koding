kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'
FeedPane  = require './feedpane'


module.exports = class PublicFeedPane extends React.Component

  @propTypes =
    thread          : React.PropTypes.instanceOf immutable.Map
    onLoadMore      : React.PropTypes.func
    popularChannels : React.PropTypes.instanceOf immutable.Map

  @defaultProps =
    thread          : immutable.Map()
    onLoadMore      : kd.noop
    popularChannels : immutable.Map()

  #  unused function!!!!
  getMessages: ->

    messages = @props.thread.get 'messages'

    return immutable.Map()  unless messages

    messages.sort (a, b) ->
      if a.get('createdAt') > b.get('createdAt') then -1
      else if a.get('createdAt') < b.get('createdAt') then return 1
      else 0

  render: ->

    return null  unless @props.thread

    <FeedPane.Container
      ref             = 'feedPane'
      key             = { @props.thread.get 'channelId' }
      thread          = { @props.thread }
      onLoadMore      = { @props.onLoadMore }
      popularChannels = { @props.popularChannels }
    />
