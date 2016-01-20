kd                = require 'kd'
$                 = require 'jquery'
React             = require 'kd-react'
ReactDOM          = require 'react-dom'
immutable         = require 'immutable'
ActivityFlux      = require 'activity/flux'
ChatPaneView      = require './view'
ScrollableContent = require 'app/components/scroller/scrollablecontent'
scrollToElement   = require 'app/util/scrollToElement'
KDReactorMixin    = require 'app/flux/base/reactormixin'

ensureScrollableElementIsVisible = require 'app/util/ensureScrollableElementIsVisible'

ChatPaneView      = ScrollableContent ChatPaneView

module.exports = class ChatPaneContainer extends React.Component

  @propsTypes =
    thread        : React.PropTypes.instanceOf immutable.Map()
    onInviteClick : React.PropTypes.func
    showItemMenu  : React.PropTypes.bool
    onLoadMore    : React.PropTypes.func


  @defaultProps =
    thread        : immutable.Map()
    onInviteClick : kd.noop
    showItemMenu  : yes
    onLoadMore    : kd.noop


  getDataBindings: ->

    return {
      selectedMessageId: ActivityFlux.getters.selectedMessageThreadId
    }


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  componentDidMount: ->

    scrollTop = @flag 'scrollPosition'
    @refs.view.scrollToPosition scrollTop  if scrollTop


  componentWillUnmount: ->

    { scrollTop } = @refs.view.getScrollParams()
    { channel }   = ActivityFlux.actions

    kd.utils.defer =>
      channel.setLastSeenTime (@channel 'id'), Date.now()
      channel.setScrollPosition (@channel 'id'), scrollTop


  componentDidUpdate: (prevProps, prevState) ->

    prevSelectedMessageId = prevState.selectedMessageId
    { selectedMessageId } = @state

    prevThread = prevProps.thread
    { thread } = @props

    return  unless prevThread and thread

    { view } = @refs

    hadEditingMessage = prevThread.getIn [ 'flags', 'hasEditingMessage' ]
    hasEditingMessage = @flag 'hasEditingMessage'

    if selectedMessageId and selectedMessageId isnt prevSelectedMessageId
      item = $("[data-message-id=#{selectedMessageId}]").get(0)
      scrollToElement item

    else if @flag 'hasSubmittingMessage'
      view.scrollToBottom()

    else if @isThresholdReached
      view.keepPosition()

    else if hasEditingMessage and not hadEditingMessage
      message = thread.get('messages').find (msg) -> msg.get '__isEditing'
      if message
        item = $("[data-message-id=#{message.get 'id'}]").get(0)

        # this delay is needed for chat input to resize its textarea
        kd.utils.wait 50, -> ensureScrollableElementIsVisible item

    else
      hasStoppedMessageEditing = not hasEditingMessage and hadEditingMessage
      hasRemovedMessage        = thread.get('messages').size < prevThread.get('messages').size

      view._update()  if hasStoppedMessageEditing or hasRemovedMessage

    @isThresholdReached = no


  onTopThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @props.onLoadMore()


  render: ->

    <ChatPaneView {...@props}
      ref                   = 'view'
      selectedMessageId     = { @state.selectedMessageId }
      onTopThresholdReached = { @bound 'onTopThresholdReached' }
      isMessagesLoading     = { @isThresholdReached }>
        {@props.children}
    </ChatPaneView>

ChatPaneContainer.include [KDReactorMixin]
