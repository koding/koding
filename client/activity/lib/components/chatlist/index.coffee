_                      = require 'lodash'
kd                     = require 'kd'
React                  = require 'kd-react'
moment                 = require 'moment'
immutable              = require 'immutable'
ChatListItem           = require 'activity/components/chatlistitem'
SimpleChatListItem     = require 'activity/components/chatlistitem/simplechatlistitem'
DateMarker             = require 'activity/components/datemarker'
NewMessageMarker       = require 'activity/components/newmessagemarker'
LoadMoreMessagesMarker = require 'activity/components/loadmoremessagesmarker'
KDReactorMixin         = require 'app/flux/base/reactormixin'
ActivityFlux           = require 'activity/flux'
Waypoint               = require 'react-waypoint'
scrollToElement        = require 'app/util/scrollToElement'
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
    onItemEditStarted : kd.noop

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


  glance: debounce 1000, {}, ->

    if kd.singletons.windowController.isFocused()
      ActivityFlux.actions.channel.glance @props.channelId


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
            channelId={channelId}
            messageId={currentMessage.get 'id'}
            position="before"
            autoload={beforeMarker.get 'autoload'}
            timestamp={currentMessage.get 'createdAt'}/>

    switch
      # if this is first message put a date marker no matter what.
      when not prevMessage
        markers.push <DateMarker date={currentMessage.get 'createdAt'} />

      # if day of previous message is not the same with current one, put a date
      # marker.
      when not currentMessageMoment.isSame prevMessageMoment, 'day'
        markers.push <DateMarker date={currentMessage.get 'createdAt'} />

    # put new message marker on top of other messages if unread count is
    # greater than currently loaded messages.
    newMessageIndex = Math.max 0, messages.size - unreadCount

    if newMessageIndex is index
      markers.push <NewMessageMarker />

    # put glancer waypoint only if all the unread messages are loaded, and on
    # the screen. Once it enters to the screen, it will glance the channel.
    if unreadCount and unreadCount <= messages.size and not isMessagesLoading
      markers.push <Waypoint onEnter={@bound 'onGlancerEnter'} />

    return markers


  getAfterMarkers: (currentMessage, prevMessage, index) ->

    { channelId } = @props

    markers = []

    if loaderMarkers = currentMessage.get 'loaderMarkers'
      if afterMarker = loaderMarkers.get 'after'
        markers.push \
          <LoadMoreMessagesMarker
            channelId={channelId}
            messageId={currentMessage.get 'id'}
            position="after"
            autoload={afterMarker.get 'autoload'}
            timestamp={currentMessage.get 'createdAt'} />

    return markers


  renderChildren: ->

    { messages, showItemMenu, channelName, channelId, onItemEditStarted } = @props
    { selectedMessageId } = @state

    lastDifferentOwnerId = null
    prevMessage = null

    children = messages.toList().reduce (children, message, i) =>

      itemProps =
        key           : message.get 'id'
        message       : message
        showItemMenu  : showItemMenu
        channelName   : channelName
        channelId     : channelId
        onEditStarted : onItemEditStarted

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

      children = children.concat @getAfterMarkers message, prevMessage, i

      prevMessage = message
      return children
    , []


  render: ->
    <div className={kd.utils.curry 'ChatList', @props.className}>
      {@renderChildren()}
    </div>


React.Component.include.call ChatList, [KDReactorMixin]

