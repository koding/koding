kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
ChatListItem          = require 'activity/components/chatlistitem'
SimpleChatListItem    = require 'activity/components/chatlistitem/simplechatlistitem'

module.exports = class ChatList extends React.Component

  @defaultProps =
    messages     : immutable.List()
    showItemMenu : yes
    firstPost    : null
    isMessagesLoading: no


  calculateRemainingMessageCount: ->

    { firstPost } = @props
    return no  unless firstPost

    repliesCount = firstPost.get 'repliesCount'
    messageCount = @props.messages.size - 1
    count = repliesCount - messageCount
    count =  if count > 0 then count else 0

    return count


  getFirstMessageId: ->

    { firstPost } = @props

    if firstPost then firstPost.get '_id' else no


  renderFirstMessageDate: (count) ->

    if @props.isMessagesLoading
      <div className='ChatItem-moreCount'>loading...</div>
    else if count
      <div className='ChatItem-moreCount'>{count} more</div>


  renderChildren: ->

    lastMessageId = null
    { messages, showItemMenu } = @props

    if @props.firstPost

      firstPostId = @props.firstPost.get '_id'
      messages = messages.set firstPostId, @props.firstPost

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


