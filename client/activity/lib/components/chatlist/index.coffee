kd                 = require 'kd'
React              = require 'kd-react'
moment             = require 'moment'
immutable          = require 'immutable'
ChatListItem       = require 'activity/components/chatlistitem'
SimpleChatListItem = require 'activity/components/chatlistitem/simplechatlistitem'
DateMarker         = require 'activity/components/datemarker'
NewMessageMarker   = require 'activity/components/newmessagemarker'


module.exports = class ChatList extends React.Component

  @defaultProps =
    messages     : immutable.List()
    showItemMenu : yes
    channelName  : ''
    isMessagesLoading: no
    unreadCount: 0


  getMarkers: (currentMessage, prevMessage, index) ->

    currentMessageMoment = moment currentMessage.get 'createdAt'

    { messages, unreadCount } = @props
    newMessageIndex = messages.size - unreadCount

    if prevMessage
      prevMessageMoment = moment prevMessage.get 'createdAt'

    markers = []

    switch
      when not prevMessage
        markers.push <DateMarker date={currentMessage.get 'createdAt'} />

      when not currentMessageMoment.isSame prevMessageMoment, 'day'
        markers.push <DateMarker date={currentMessage.get 'createdAt'} />

    if newMessageIndex is index
      markers.push <NewMessageMarker />

    return markers


  renderChildren: ->

    { messages, showItemMenu, channelName } = @props

    lastDifferentOwnerId = null
    prevMessage = null

    children = messages.toList().reduce (children, message, i) =>

      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu
        channelName  : channelName

      children = children.concat @getMarkers message, prevMessage, i

      if lastDifferentOwnerId and lastDifferentOwnerId is message.get 'accountId'
        children.push \
          <SimpleChatListItem {...itemProps } />
      else
        lastDifferentOwnerId = message.get 'accountId'
        children.push \
          <ChatListItem {...itemProps} />

      prevMessage = message
      return children
    , []


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren()}
    </div>


