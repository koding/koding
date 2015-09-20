kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages     : immutable.List()
    showItemMenu : yes
    channelName  : ''
    isMessagesLoading: no


  renderChildren: ->

    lastMessageId = null
    { messages, showItemMenu, channelName } = @props

    messages.toList().map (message, i) ->

      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu
        channelName  : channelName

      if lastMessageId and lastMessageId is message.get 'accountId'
        <SimpleChatListItem {...itemProps} />
      else
        lastMessageId = message.get 'accountId'
        <ChatListItem {...itemProps} />


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren()}
    </div>


