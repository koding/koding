kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages     : immutable.List()
    showItemMenu : yes
    thread       : {}


  calculateRemainingMessageCount: ->

    return no  unless @props.thread.message

    repliesCount = @props.thread.getIn ['message', 'repliesCount']
    messageCount = @props.messages.size - 1
    count = repliesCount - messageCount
    count =  if count > 0 then count else 0

    return count


  getFirstMessageId: ->

    if @props.thread.get 'message'
      return @props.thread.getIn ['message', '_id']

    return no


  renderFirstMessageDate: (count) ->

    if @props.thread?.getIn ['flags', 'isMessagesLoading']
      <div className='ChatItem-moreCount'>loading...</div>
    else if count
      <div className='ChatItem-moreCount'>{count} more</div>


  renderChildren: ->

    lastMessageId = null
    { messages, showItemMenu } = @props

    messages.map (message, i) =>
      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu

      count          = @calculateRemainingMessageCount()
      firstMessageId = @getFirstMessageId()

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


