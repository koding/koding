kd        = require 'kd'
React     = require 'kd-react'
FeedItem  = require './feeditem'
immutable = require 'immutable'

module.exports = class FeedList extends React.Component

  @propTypes =
    messages  : React.PropTypes.instanceOf immutable.Map
    channelId : React.PropTypes.string

  @defaultProps =
    messages  : immutable.Map()
    channelId : null


  renderChildren: ->

    { channelId } = @props

    @props.messages.toList().map (msg) ->
      <FeedItem.Container channelId = { channelId } key = { msg.get 'id' } message = { msg } />


  render: ->

    <div className={kd.utils.curry 'FeedList', @props.className}>
      { @renderChildren().toList() }
    </div>
