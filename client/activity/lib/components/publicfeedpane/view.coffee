kd            = require 'kd'
React         = require 'kd-react'
ReactDOM      = require 'react-dom'
immutable     = require 'immutable'
FeedPane      = require './feedpane'
ActivityFlux  = require 'activity/flux'
ScrollerMixin = require 'app/components/scroller/scrollermixin'
ResultState   = require 'activity/constants/resultStates'

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
