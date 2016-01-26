_                      = require 'lodash'
kd                     = require 'kd'
React                  = require 'kd-react'
ReactDOM               = require 'react-dom'
moment                 = require 'moment'
immutable              = require 'immutable'
ChatListItem           = require 'activity/components/chatlistitem'
SimpleChatListItem     = require 'activity/components/chatlistitem/simplechatlistitem'
DateMarker             = require 'activity/components/datemarker'
NewMessageMarker       = require 'activity/components/newmessagemarker'
LoadMoreMessagesMarker = require 'activity/components/loadmoremessagesmarker'
ActivityFlux           = require 'activity/flux'
Waypoint               = require 'react-waypoint'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'

debounce = (delay, options, fn) -> _.debounce fn, delay, options


module.exports = class ChatList extends React.Component

  @defaultProps =
    messages          : immutable.List()
    showItemMenu      : yes
    channelId         : ''
    channelName       : ''
    unreadCount       : 0
    isMessagesLoading : no
    selectedMessageId : null

  componentDidMount: ->

    kd.singletons.windowController.addFocusListener @bound 'handleFocus'


  componentDidUpdate: -> @cacheDateMarkers()


  glance: debounce 1000, {}, ->

    if kd.singletons.windowController.isFocused()
      ActivityFlux.actions.channel.glance @props.channelId


  handleFocus: (focused) ->

    @glance()  if focused and @props.unreadCount


  onGlancerEnter: -> @glance()


  getBeforeMarkers: (currentMessage, prevMessage, index) ->

    currentMessageMoment = moment currentMessage.get 'createdAt'

    if prevMessage
      prevMessageMoment = moment prevMessage.get 'createdAt'

    { messages, unreadCount, channelId, isMessagesLoading } = @props

    markers = []

    if loaderMarkers = currentMessage.get 'loaderMarkers'
      if beforeMarker = loaderMarkers.get 'before'
        markers.push \
          <LoadMoreMessagesMarker
            key="loadafter-#{currentMessage.get 'id'}"
            channelId={channelId}
            messageId={currentMessage.get 'id'}
            position="before"
            autoload={beforeMarker.get 'autoload'}
            timestamp={currentMessage.get 'createdAt'}/>

    switch
      # if this is first message put a date marker no matter what.
      when not prevMessage
        markers.push \
          <DateMarker
            key={currentMessage.get 'createdAt'}
            date={currentMessage.get 'createdAt'} />

      # if day of previous message is not the same with current one, put a date
      # marker.
      when not currentMessageMoment.isSame prevMessageMoment, 'day'
        markers.push \
          <DateMarker
            key={currentMessage.get 'createdAt'}
            date={currentMessage.get 'createdAt'} />

    # put new message marker on top of other messages if unread count is
    # greater than currently loaded messages.
    newMessageIndex = Math.max 0, messages.size - unreadCount

    if newMessageIndex is index
      markers.push <NewMessageMarker />

    # put glancer waypoint only if all the unread messages are loaded, and on
    # the screen. Once it enters to the screen, it will glance the channel.
    if index is messages.size - unreadCount and not isMessagesLoading
      markers.push <Waypoint onEnter={@bound 'onGlancerEnter'} />

    return markers


  getAfterMarkers: (currentMessage, prevMessage, index) ->

    { channelId } = @props

    markers = []

    if loaderMarkers = currentMessage.get 'loaderMarkers'
      if afterMarker = loaderMarkers.get 'after'
        markers.push \
          <LoadMoreMessagesMarker
            key="loadafter-#{currentMessage.get 'id'}"
            channelId={channelId}
            messageId={currentMessage.get 'id'}
            position="after"
            autoload={afterMarker.get 'autoload'}
            timestamp={currentMessage.get 'createdAt'} />

    return markers


  cacheDateMarkers: ->

    filter    = Array.prototype.filter
    container = ReactDOM.findDOMNode this
    markers   = container.querySelectorAll '.DateMarker'

    @dateMarkers = filter.call markers, (node) ->
      return node.className.indexOf('DateMarker-fixed') is -1


  updateDateMarkersPosition: (scrollTop, left) ->

    @dateMarkers.forEach (dateMarker) ->

      { offsetTop, offsetWidth } = dateMarker
      fixedMarker = dateMarker.querySelector '.DateMarker-fixed'

      if offsetTop >= scrollTop

        fixedMarker.style.display = 'none'

      else if scrollTop > offsetTop

        fixedMarker.style.left    = "#{left}px"
        fixedMarker.style.width   = "#{offsetWidth}px"
        fixedMarker.style.display = 'block'


  renderChildren: ->

    { messages, showItemMenu, channelName } = @props
    { channelId, selectedMessageId } = @props

    lastDifferentOwnerId     = null
    prevMessage              = null
    lastMessageCreatedAt     = null
    timeDiff                 = 0
    isLessThanFiveMinutes    = no

    children = messages.toList().reduce (children, message, i) =>

      itemProps =
        key           : message.get 'id'
        message       : message
        showItemMenu  : showItemMenu
        channelName   : channelName
        channelId     : channelId

      createdAt = message.get 'createdAt'

      timeDiff  = new Date(createdAt).getTime() - lastMessageCreatedAt  if lastMessageCreatedAt
      isLessThanFiveMinutes = timeDiff < (5 * 60 * 1000)

      if selectedMessageId is message.get 'id'
        itemProps['isSelected'] = yes

      children = children.concat @getBeforeMarkers message, prevMessage, i

      if lastDifferentOwnerId and lastDifferentOwnerId is message.get('accountId') and isLessThanFiveMinutes
        children.push \
          <SimpleChatListItem {...itemProps } />
      else
        lastDifferentOwnerId = message.get 'accountId'
        children.push \
          <ChatListItem {...itemProps} />

      lastMessageCreatedAt = new Date(createdAt).getTime()

      children = children.concat @getAfterMarkers message, prevMessage, i

      prevMessage = message
      return children
    , []


  render: ->

    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren()}
    </div>

