kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
ChatInputWidget = require 'activity/components/chatinputwidget'
ActivityFlux    = require 'activity/flux'
Scroller        = require 'app/components/scroller'
ScrollerMixin   = require 'app/components/scroller/scrollermixin'



module.exports = class ChatPane extends React.Component

  @include [ScrollerMixin]

  @defaultProps =
    title         : null
    messages      : null
    isDataLoading : no
    onLoadMore    : kd.noop
    isParticipant : no
    showItemMenu  : yes


  onSubmit: (event) -> @props.onSubmit? event


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
        />
      </Scroller>
    </section>


  onFollowChannelButtonClick: -> @props.onFollowChannelButtonClick()


  renderFollowChannel: ->

    <div className="ChatPane-subscribeContainer">
      YOU NEED TO FOLLOW THIS CHANNEL TO JOIN CONVERSATION
      <button ref="button" className="Button Button-followChannel" onClick={@bound 'onFollowChannelButtonClick'}>FOLLOW CHANNEL</button>
    </div>


  renderFooter: ->

    return null  unless @props.messages

    footerInnerComponent = if @props.isParticipant
    then <ChatInputWidget onSubmit={@bound 'onSubmit'} />
    else @renderFollowChannel()

    <footer className="ChatPane-footer">
      {footerInnerComponent}
    </footer>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        {@renderBody()}
        {@renderFooter()}
      </section>
    </div>


