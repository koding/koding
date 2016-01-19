kd                = require 'kd'
React             = require 'kd-react'
ReactDOM          = require 'react-dom'
immutable         = require 'immutable'
ActivityFlux      = require 'activity/flux'
ChatPaneView      = require './view'
ScrollableContent = require 'app/components/scroller/scrollablecontent'

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


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  componentDidMount: ->

    scrollTop = @flag 'scrollPosition'
    @refs.view.scrollTo scrollTop  if scrollTop


  componentWillUnmount: ->

    { scrollTop } = @refs.view.getScrollParams()
    { channel }   = ActivityFlux.actions

    kd.utils.defer =>
      channel.setLastSeenTime (@channel 'id'), Date.now()
      channel.setScrollPosition (@channel 'id'), scrollTop


  componentDidUpdate: (prevProps) ->

    { thread } = prevProps
    return  unless thread

    { view } = @refs

    if thread.getIn [ 'flags', 'hasSubmittingMessage' ]
      view.scrollToBottom()
    else if @isThresholdReached
      view.keepPosition()
    else
      hadEditingMessage        = thread.getIn [ 'flags', 'hasEditingMessage' ]
      hasStoppedMessageEditing = not @flag('hasEditingMessage') and hadEditingMessage
      hasRemovedMessage        = @props.thread?.get('messages').size < thread.get('messages').size

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
      onTopThresholdReached = { @bound 'onTopThresholdReached' }
      isMessagesLoading     = { @isThresholdReached }>
        {@props.children}
    </ChatPaneView>

