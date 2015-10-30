kd                   = require 'kd'
React                = require 'kd-react'
ChatList             = require 'activity/components/chatlist'
ActivityFlux         = require 'activity/flux'
Scroller             = require 'app/components/scroller'
ScrollerMixin        = require 'app/components/scroller/scrollermixin'
EmojiPreloaderMixin  = require 'activity/components/emojipreloadermixin'
ChannelInfoContainer = require 'activity/components/channelinfocontainer'
scrollToTarget       = require 'app/util/scrollToTarget'


module.exports = class ChatPane extends React.Component

  @defaultProps =
    title          : null
    messages       : null
    isDataLoading  : no
    onInviteOthers : kd.noop
    showItemMenu   : yes


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  componentDidMount: ->

    scroller = React.findDOMNode @refs.scrollContainer
    scrollTop = @flag 'scrollPosition'

    scroller.scrollTop  = scrollTop  if scrollTop
    kd.utils.wait 50, -> _showScroller scroller


  componentWillUnmount: ->

    scroller = React.findDOMNode @refs.scrollContainer

    { scrollTop } = scroller
    { channel }   = ActivityFlux.actions

    _hideScroller scroller
    channel.setScrollPosition (@channel 'id'), scrollTop


  componentWillUpdate: (nextProps, nextState) ->

    return  unless nextProps?.thread

    { thread } = nextProps

    isMessageBeingSubmitted = @flag 'isMessageBeingSubmitted'

    @shouldScrollToBottom = yes  if isMessageBeingSubmitted


  onTopThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @props.onLoadMore()


  renderChannelInfoContainer: ->

    return null  unless @props.thread

    messagesSize        = @props.thread.get('messages').size
    scrollContainer     = React.findDOMNode @refs.scrollContainer
    reachedFirstMessage = @flag 'reachedFirstMessage'

    if not reachedFirstMessage
      return null

    <ChannelInfoContainer
      ref='ChannelInfoContainer'
      key={@channel 'id'}
      thread={@props.thread}
      onInviteOthers={@props.onInviteOthers} />


  onItemEditStarted: (itemElement) ->

    return  unless itemElement

    # this delay is a time needed to chat input
    # in order to resize its textarea
    kd.utils.wait 50, =>
      scrollContainer = React.findDOMNode @refs.scrollContainer
      scrollToTarget scrollContainer, itemElement


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      ref='scrollContainer'
      hasMore={@props.thread.get('messages').size}
      onTopThresholdReached={@bound 'onTopThresholdReached'}>
      {@renderChannelInfoContainer()}
      <ChatList
        ref='ChatList'
        isMessagesLoading={@isThresholdReached}
        messages={@props.thread.get 'messages'}
        showItemMenu={@props.showItemMenu}
        channelId={@channel 'id'}
        channelName={@channel 'name'}
        unreadCount={@channel 'unreadCount'}
        onItemEditStarted={@bound 'onItemEditStarted'}
      />
    </Scroller>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        <section className="ChatPane-body" ref="ChatPaneBody">
          {@renderBody()}
          {@props.children}
        </section>
      </section>
    </div>


React.Component.include.call ChatPane, [ScrollerMixin, EmojiPreloaderMixin]


_hideScroller = (scroller) -> scroller?.style.opacity = 0


_showScroller = (scroller) -> scroller?.style.opacity = 1


