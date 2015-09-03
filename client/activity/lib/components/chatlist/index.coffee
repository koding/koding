kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages     : immutable.List()
    showItemMenu : yes


  renderChildren: ->

    lastMessageId = null
    { messages, showItemMenu } = @props

    messages.map (message, i) ->
      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu

      if lastMessageId and lastMessageId is message.get 'accountId'
        return <SimpleChatListItem {...itemProps} />
      else
        lastMessageId = message.get 'accountId'
        return <ChatListItem {...itemProps} />


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren().toList()}
    </div>


