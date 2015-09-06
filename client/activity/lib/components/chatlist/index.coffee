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
    { messages, showItemMenu, thread } = @props

    messages.map (message, i) =>
      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu

      count          = @calculateRemainingMessageCount()
      firstMessageId = thread.getIn ['message', '_id']

      if lastMessageId and lastMessageId is message.get 'accountId'
        <SimpleChatListItem {...itemProps} />
      else if firstMessageId is message.get('_id') and count
        <div className='ChatPane-firstMessage'>
          <ChatListItem {...itemProps} />
          {@renderFirstMessageDate(count)}
        </div>
      else
        lastMessageId = message.get 'accountId'
        <ChatListItem {...itemProps} />


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren().toList()}
    </div>


