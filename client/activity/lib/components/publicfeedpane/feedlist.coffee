kd       = require 'kd'
React    = require 'kd-react'
FeedItem = require './feeditem'

module.exports = class FeedList extends React.Component

  defaultProps =
    channelId : null


  renderChildren: ->

    { channelId } = @props

    @props.messages.toList().map (msg) ->
      <FeedItem channelId={channelId} key={msg.get 'id'} message={msg} />


  render: ->
    <div className={kd.utils.curry 'FeedList', @props.className}>
      {@renderChildren().toList()}
    </div>
