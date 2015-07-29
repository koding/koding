kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
ConsequentMessageItem = require 'activity/components/chatlistitem/consequentmessageitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages: immutable.List()

  renderChildren: ->

    lastMessageId = undefined

    @props.messages.map (message, i) ->
      if lastMessageId and lastMessageId == message.get 'accountId'
        return <ConsequentMessageItem key={message.get 'id'} message={message} />
      else
        lastMessageId = message.get 'accountId'
        return <ChatListItem key={message.get 'id'} message={message} />


  render: ->
    <div className={kd.utils.curry 'ChatList padded', @props.className}>
      {@renderChildren().toList()}
    </div>


