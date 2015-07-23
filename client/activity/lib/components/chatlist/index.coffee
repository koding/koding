kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ChatListItem = require 'activity/components/chatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages: immutable.List()

  renderChildren: ->
    @props.messages.map (message) ->
      <ChatListItem key={message.get 'id'} message={message} />


  render: ->
    <div className={kd.utils.curry 'ChatList padded', @props.className}>
      {@renderChildren().toList()}
    </div>


