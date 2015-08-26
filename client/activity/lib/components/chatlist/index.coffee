kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
emojify               = require 'emojify.js'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages: immutable.List()


  componentDidUpdate: ->

    ChatList = React.findDOMNode this.refs.ChatList
    emojify.run ChatList  if ChatList


  renderChildren: ->

    lastMessageId = null

    @props.messages.map (message, i) ->
      if lastMessageId and lastMessageId is message.get 'accountId'
        return <SimpleChatListItem key={message.get 'id'} message={message} />
      else
        lastMessageId = message.get 'accountId'
        return <ChatListItem key={message.get 'id'} message={message} />


  render: ->
    <div ref="ChatList" className={kd.utils.curry 'ChatList padded', @props.className}>
      {@renderChildren().toList()}
    </div>


