kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
ChatInputWidget = require 'activity/components/chatinputwidget'
Scroller        = require 'app/components/scroller'
ActivityFlux    = require 'activity/flux'


module.exports = class ChatPane extends React.Component

  @defaultProps =
    title         : null
    messages      : null
    isDataLoading : no
    onLoadMore    : kd.noop
    isParticipant : no


  componentWillUpdate: ->

    return  unless @refs?.scrollContainer

    { @scrollTop, offsetHeight, @scrollHeight } = React.findDOMNode @refs.scrollContainer
    @shouldScrollToBottom = @scrollTop + offsetHeight is @scrollHeight


  componentDidUpdate: ->

    return  unless @refs?.scrollContainer

    element = React.findDOMNode @refs.scrollContainer

    if @shouldScrollToBottom
      element.scrollTop = element.scrollHeight
    else
      element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)


  onSubmit: (event) -> @props.onSubmit? event


  onTopThresholdReached: -> @props.onLoadMore()


  renderBody: ->
    return null  unless @props.messages

    <section className="ChatPane-body" ref="ChatPaneBody">
      <Scroller
        onTopThresholdReached={@bound 'onTopThresholdReached'}
        ref="scrollContainer">
        <ChatList messages={messages} />
      </Scroller>
    </section>


  onFollowChannelButtonClick: -> @props.onFollowChannelButtonClick()


  renderFollowChannel: ->

    <div className="ChatPane-subscribeContainer">
      YOU NEED TO FOLLOW THIS CHANNEL TO JOIN CONVERSATION
      <button ref="button" className="Button Button-followChannel" onClick={@bound 'onFollowChannelButtonClick'}>FOLLOW CHANNEL</button>
    </div>


  renderFooter: ->

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


