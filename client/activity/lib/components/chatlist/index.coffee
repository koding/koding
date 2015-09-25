kd                 = require 'kd'
React              = require 'kd-react'
moment             = require 'moment'
immutable          = require 'immutable'
ChatListItem       = require 'activity/components/chatlistitem'
SimpleChatListItem = require 'activity/components/chatlistitem/simplechatlistitem'
DateMarker         = require 'activity/components/datemarker'
NewMessageMarker   = require 'activity/components/newmessagemarker'
KDReactorMixin     = require 'app/flux/reactormixin'
ActivityFlux       = require 'activity/flux'
scrollToElement    = require 'app/util/scrollToElement'


module.exports = class ChatList extends React.Component

  @defaultProps =
    messages          : immutable.List()
    showItemMenu      : yes
    channelName       : ''
    isMessagesLoading : no
    selectedMessageId : null


  constructor: (props) ->

    super props

    @state = { selectedMessageId: @props.selectedMessageId }


  getDataBindings: ->
    return {
      selectedMessageId: ActivityFlux.getters.selectedMessageThreadId
    }


  componentDidUpdate: (prevProps, prevState) ->

    prevSelectedId = prevState.selectedMessageId
    currentSelectedId = @state.selectedMessageId

    if currentSelectedId and currentSelectedId isnt prevSelectedId
      target = React.findDOMNode @refs.selectedComponent
      scrollToElement target


  getBeforeMarkers: (currentMessage, prevMessage, index) ->

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
    { selectedMessageId } = @state

    lastDifferentOwnerId = null
    prevMessage = null

    children = messages.toList().reduce (children, message, i) =>

      itemProps =
        key          : message.get 'id'
        message      : message
        showItemMenu : showItemMenu
        channelName  : channelName

      if selectedMessageId is message.get 'id'
        itemProps['isSelected'] = yes
        itemProps['ref'] = 'selectedComponent'

      children = children.concat @getBeforeMarkers message, prevMessage, i

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


React.Component.include.call ChatList, [KDReactorMixin]

