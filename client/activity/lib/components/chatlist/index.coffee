kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages: immutable.List()

  renderChildren: ->

    lastMessageId = undefined

    @props.messages.map (message, i) ->
      if lastMessageId and lastMessageId is message.get 'accountId'
        return <SimpleChatListItem key={message.get 'id'} message={message} />
      else
        lastMessageId = message.get 'accountId'
        return <ChatListItem key={message.get 'id'} message={message} />


  render: ->
    <div className={kd.utils.curry 'ChatList padded', @props.className}>
      {@renderChildren().toList()}
    </div>


