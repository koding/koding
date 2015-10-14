kd                   = require 'kd'
React                = require 'kd-react'
ChatList             = require 'activity/components/chatlist'
ActivityFlux         = require 'activity/flux'
Scroller             = require 'app/components/scroller'
ScrollerMixin        = require 'app/components/scroller/scrollermixin'
ChannelInfoContainer = require 'activity/components/channelinfocontainer'


module.exports = class ChatPane extends React.Component

  @defaultProps =
    title             : null
    messages          : null
    isDataLoading     : no
    afterInviteOthers : kd.noop
    showItemMenu      : yes


  componentWillUpdate: (nextProps, nextState) ->

    return  unless nextProps?.thread

    { thread } = nextProps

    isMessageBeingSubmitted = thread.getIn ['flags', 'isMessageBeingSubmitted']

    @shouldScrollToBottom = yes  if isMessageBeingSubmitted


  onTopThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @props.onLoadMore()


  afterInviteOthers: -> @props.afterInviteOthers()


  channel: (key) -> @props.thread.getIn ['channel', key]


  renderChannelInfoContainer: ->

    if @props.thread?.getIn(['flags', 'reachedFirstMessage'])
      <ChannelInfoContainer
        ref='ChannelInfoContainer'
        key={@channel 'id'}
        thread={@props.thread}
        afterInviteOthers={@bound 'afterInviteOthers'} />


  beforeScrollDidUpdate: ->

    @setPaddedClassName()


  setPaddedClassName: ->

    list                       = React.findDOMNode @refs.ChatList
    scrollContainer            = React.findDOMNode @refs.scrollContainer
    channelInfoContainer       = React.findDOMNode @refs.ChannelInfoContainer
    listHeight                 = list.offsetHeight
    scrollContainerHeight      = scrollContainer.offsetHeight
    channelInfoContainerHeight = 0

    if channelInfoContainer
      channelInfoContainerHeight = channelInfoContainer.offsetHeight

    if listHeight < scrollContainerHeight - channelInfoContainerHeight
    then list.classList.add 'padded'
    else list.classList.remove 'padded'


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      ref="scrollContainer"
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


React.Component.include.call ChatPane, [ScrollerMixin]

