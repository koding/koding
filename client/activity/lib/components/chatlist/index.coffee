kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ChatListItem = require 'activity/components/chatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages: immutable.List()


  renderChildren: ->
    @props.messages.map (message) ->
      <ChatListItem message={message} />


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren().toList()}
    </div>


