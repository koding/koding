kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
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

    scroller = ReactDOM.findDOMNode @refs.scrollContainer
    scrollTop = @flag 'scrollPosition'

    scroller.scrollTop  = scrollTop  if scrollTop
    _showScroller scroller


  onScroll: -> @setDateMarkersPosition()


  afterScrollDidUpdate: ->

    @setFilteredMarkers()
    @setDateMarkersPosition()


  setFilteredMarkers: ->

    filter   = Array.prototype.filter
    chatList = ReactDOM.findDOMNode @refs.ChatList
    @markers = chatList.querySelectorAll '.DateMarker'

    @filteredMarkers = filter.call @markers, (node) ->
      return node.className.indexOf('DateMarker-fixed') is -1


  setDateMarkersPosition: ->

    scroller = ReactDOM.findDOMNode @refs.scrollContainer
    left = scroller.getBoundingClientRect().left
    { scrollTop, offsetHeight } = scroller

    return  unless scrollTop and offsetHeight

    @filteredMarkers.forEach (dateMarker) ->

      { offsetTop, offsetWidth } = dateMarker
      fixedMarker = dateMarker.querySelector '.DateMarker-fixed'

      if offsetTop >= scrollTop

        fixedMarker.style.display = 'none'

      else if scrollTop > offsetTop

        fixedMarker.style.left    = "#{left}px"
        fixedMarker.style.width   = "#{offsetWidth}px"
        fixedMarker.style.display = 'block'


  componentWillUnmount: ->

    scroller = ReactDOM.findDOMNode @refs.scrollContainer

    { scrollTop } = scroller
    { channel }   = ActivityFlux.actions

    _hideScroller scroller
    kd.utils.defer =>
      channel.setLastSeenTime (@channel 'id'), Date.now()
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
      scrollContainer = ReactDOM.findDOMNode @refs.scrollContainer
      scrollToTarget scrollContainer, itemElement


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      style={{height: 'auto'}}
      ref='scrollContainer'
      onScroll={@bound 'onScroll'}
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


