kd                  = require 'kd'
React               = require 'kd-react'
ReactDOM            = require 'react-dom'
immutable           = require 'immutable'
Scroller            = require 'app/components/scroller'
ChatList            = require 'activity/components/chatlist'
ChannelInfo         = require 'activity/components/channelinfo'
UnreadMessagesLabel = require './unreadmessageslabel'
EmojiPreloaderMixin = require 'activity/components/emojipreloadermixin'
ScrollableContent   = require 'app/components/scroller/scrollablecontent'

class ChatPaneView extends React.Component

  @propsTypes =
    thread                 : React.PropTypes.instanceOf immutable.Map
    onInviteClick          : React.PropTypes.func
    showItemMenu           : React.PropTypes.bool
    isMessagesLoading      : React.PropTypes.bool
    onTopThresholdReached  : React.PropTypes.func
    selectedMessageId      : React.PropTypes.string
    onGlance               : React.PropTypes.func
    onScroll               : React.PropTypes.func
    onJumpToUnreadMessages : React.PropTypes.func


  @defaultProps =
    thread                 : immutable.Map()
    onInviteClick          : kd.noop
    showItemMenu           : yes
    isMessagesLoading      : no
    onTopThresholdReached  : kd.noop
    selectedMessageId      : ''
    onGlance               : kd.noop
    onScroll               : kd.noop
    onJumpToUnreadMessages : kd.noop


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  show: ->

    scroller = ReactDOM.findDOMNode @refs.scroller
    scroller.style.opacity = 1


  hide: ->

    scroller = ReactDOM.findDOMNode @refs.scroller
    scroller.style.opacity = 0


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
      ref='scroller'
      onScroll={@props.onScroll}
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
        onGlance={@props.onGlance}
      />
    </Scroller>


  render: ->

    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="Pane-contentWrapper">
        <section className="Pane-body" ref="ChatPaneBody">
          <UnreadMessagesLabel
            ref='UnreadCountLabel'
            unreadCount={@channel 'unreadCount'}
            onJump={@props.onJumpToUnreadMessages}
            onMarkAsRead={@props.onMarkAsRead}
          />
          {@renderBody()}
          {@props.children}
        </section>
      </section>
    </div>


ChatPaneView.include [EmojiPreloaderMixin]


module.exports = ScrollableContent ChatPaneView
