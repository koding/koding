kd                  = require 'kd'
React               = require 'kd-react'
ReactDOM            = require 'react-dom'
immutable           = require 'immutable'
ActivityFlux        = require 'activity/flux'
Scroller            = require 'app/components/scroller'
scrollToTarget      = require 'app/util/scrollToTarget'
ChatList            = require 'activity/components/chatlist'
ChannelInfo         = require 'activity/components/channelinfo'
EmojiPreloaderMixin = require 'activity/components/emojipreloadermixin'

module.exports = class ChatPaneView extends React.Component

  @propsTypes =
    thread                : React.PropTypes.instanceOf immutable.Map()
    onInviteClick         : React.PropTypes.func
    showItemMenu          : React.PropTypes.bool
    isMessagesLoading     : React.PropTypes.bool
    onTopThresholdReached : React.PropTypes.func


  @defaultProps =
    thread                : immutable.Map()
    onInviteClick         : kd.noop
    showItemMenu          : yes
    isMessagesLoading     : no
    onTopThresholdReached : kd.noop


  flag: (key) -> @props.thread?.getIn ['flags', key]
  channel: (key) -> @props.thread?.getIn ['channel', key]


  componentDidMount: ->

    scroller = ReactDOM.findDOMNode @refs.scrollContainer
    _showScroller scroller


  onScroll: -> @setDateMarkersPosition()


  setFilteredMarkers: ->

    filter   = Array.prototype.filter
    chatList = ReactDOM.findDOMNode @refs.ChatList
    markers  = chatList.querySelectorAll '.DateMarker'

    @filteredMarkers = filter.call markers, (node) ->
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
    _hideScroller scroller


  componentDidUpdate: (prevProps) ->

    @setFilteredMarkers()
    @setDateMarkersPosition()


  getScroller: -> @refs.scrollContainer


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
        onItemEditStarted={@bound 'onItemEditStarted'}
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


_hideScroller = (scroller) -> scroller?.style.opacity = 0


_showScroller = (scroller) -> scroller?.style.opacity = 1
