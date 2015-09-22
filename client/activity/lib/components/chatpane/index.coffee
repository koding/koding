kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
ActivityFlux    = require 'activity/flux'
Scroller        = require 'app/components/scroller'
ScrollerMixin   = require 'app/components/scroller/scrollermixin'


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
    @shouldScrollToBottom = yes  if isMessageBeingSubmitted


  onTopThresholdReached: -> @props.onLoadMore()


  renderBody: ->

    return null  unless @props.messages

    <section className="ChatPane-body" ref="ChatPaneBody">
      <Scroller
        onTopThresholdReached={@bound 'onTopThresholdReached'}
        ref="scrollContainer">
        <ChatList
          isMessagesLoading={@props.thread?.getIn ['flags', 'isMessagesLoading']}
          firstPost={@props.thread.get 'message'}
          messages={@props.messages}
          showItemMenu={@props.showItemMenu}
          channelName={@props.thread.getIn ['channel', 'name']}
        />
      </Scroller>
    </section>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        {@renderBody()}
        {@props.children}
      </section>
    </div>


React.Component.include.call ChatPane, [ScrollerMixin]

