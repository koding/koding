kd = require 'kd'
React = require 'kd-react'

FeedItem = require './feeditem'

module.exports = class FeedList extends React.Component

  renderChildren: ->

    @props.messages.map (msg) ->
      <FeedItem key={msg.get 'id'} message={msg} />


  render: ->
    <div className={kd.utils.curry 'FeedList', @props.className}>
      {@renderChildren().toList()}
    </div>

