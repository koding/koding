kd                  = require 'kd'
React               = require 'kd-react'
ReactDOM            = require 'react-dom'
immutable           = require 'immutable'
Scroller            = require 'app/components/scroller'
ChatList            = require 'activity/components/chatlist'
ChannelInfo         = require 'activity/components/channelinfo'
EmojiPreloaderMixin = require 'activity/components/emojipreloadermixin'
ScrollableContent   = require 'app/components/scroller/scrollablecontent'

class ChatPaneView extends React.Component

  @propsTypes =
    thread                : React.PropTypes.instanceOf immutable.Map()
    onInviteClick         : React.PropTypes.func
    showItemMenu          : React.PropTypes.bool
    isMessagesLoading     : React.PropTypes.bool
    onTopThresholdReached : React.PropTypes.func
    selectedMessageId     : React.PropTypes.string


  @defaultProps =
    thread                : immutable.Map()
    onInviteClick         : kd.noop
    showItemMenu          : yes
    isMessagesLoading     : no
    onTopThresholdReached : kd.noop
    selectedMessageId     : ''


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  getScroller: -> @refs.scrollContainer


  componentDidMount: ->

    scroller = ReactDOM.findDOMNode @getScroller()
    _showScroller scroller


  componentWillUnmount: ->

    scroller = ReactDOM.findDOMNode @getScroller()
    _hideScroller scroller


  componentDidUpdate: (prevProps) -> @updateDateMarkersPosition()


  onScroll: -> @updateDateMarkersPosition()


  updateDateMarkersPosition: ->

    scroller = ReactDOM.findDOMNode @getScroller()
    { scrollTop, offsetHeight } = scroller

    return  unless scrollTop and offsetHeight

    left = scroller.getBoundingClientRect().left
    @refs.ChatList.updateDateMarkersPosition scrollTop, left


  renderChannelInfoContainer: ->

    return null  unless @props.thread

    messagesSize        = @props.thread.get('messages').size
    reachedFirstMessage = @flag 'reachedFirstMessage'

    if not reachedFirstMessage
      return null

    <ChannelInfo.Container
      ref='ChannelInfoContainer'
      key={@channel 'id'}
      channel={@props.thread.get 'channel'}
      onInviteClick={@props.onInviteClick} />


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      data-is-scroller=yes
      style={{height: 'auto'}}
      ref='scrollContainer'
      onScroll={@bound 'onScroll'}
      hasMore={@props.thread.get('messages').size}
      onTopThresholdReached={@props.onTopThresholdReached}>
      {@renderChannelInfoContainer()}
      <ChatList
        ref='ChatList'
        isMessagesLoading={@props.isMessagesLoading}
        messages={@props.thread.get 'messages'}
        showItemMenu={@props.showItemMenu}
        channelId={@channel 'id'}
        channelName={@channel 'name'}
        unreadCount={@channel 'unreadCount'}
        selectedMessageId={@props.selectedMessageId}
      />
    </Scroller>


  render: ->

    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="Pane-contentWrapper">
        <section className="Pane-body" ref="ChatPaneBody">
          {@renderBody()}
          {@props.children}
        </section>
      </section>
    </div>


React.Component.include.call ChatPaneView, [EmojiPreloaderMixin]


module.exports = ScrollableContent ChatPaneView


_hideScroller = (scroller) -> scroller?.style.opacity = 0


_showScroller = (scroller) -> scroller?.style.opacity = 1
