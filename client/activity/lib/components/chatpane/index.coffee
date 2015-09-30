kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
ActivityFlux    = require 'activity/flux'
Scroller        = require 'app/components/scroller'
ScrollerMixin   = require 'app/components/scroller/scrollermixin'

dateFormat           = require 'dateformat'

module.exports = class ChatPane extends React.Component

  @defaultProps =
    title         : null
    messages      : null
    isDataLoading : no
    onLoadMore    : kd.noop
    showItemMenu  : yes


  componentWillUpdate: (nextProps, nextState) ->

    return  unless nextProps?.thread

    { thread } = nextProps
    isMessageBeingSubmitted = thread.getIn ['flags', 'isMessageBeingSubmitted']
    @shouldScrollToBottom   = yes  if isMessageBeingSubmitted


  onTopThresholdReached: -> @props.onLoadMore()


  channel: (key) -> @props.thread.getIn ['channel', key]


  getChannelCreationDate: (givenDate) ->

    timeFormat     = 'h:MM TT'

    relativeDates  = ["Today", "Yesterday"]
    today          = new Date
    givenDate      = new Date givenDate
    dateDifference = today.getDate() - givenDate.getDate()
    dateString     = relativeDates[dateDifference] or dateFormat givenDate, "mmmm d"
    if relativeDates[dateDifference]
      dateString     = "#{dateString} at #{dateFormat givenDate, timeFormat}"
    else
      dateString     = "#{dateString}th."

  renderBody: ->

    return null  unless @props.messages?.size

    <Scroller
      onTopThresholdReached={@bound 'onTopThresholdReached'}
      ref="scrollContainer">
      <ChatList
        isMessagesLoading={@props.thread?.getIn ['flags', 'isMessagesLoading']}
        messages={@props.messages}
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

