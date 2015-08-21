kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
InfiniteScroll  = require 'app/components/infinitescroll'
ChatInputWidget = require 'activity/components/chatinputwidget'
ActivityFlux    = require 'activity/flux'


module.exports = class ChatPane extends React.Component

  @defaultProps =
    title                    : null
    messages                 : null
    isDataLoading            : no
    onScrollThresholdReached : kd.noop
    isParticipant            : no


  componentDidUpdate: ->

    list = React.findDOMNode(@refs.ChatList)
    body = React.findDOMNode(@refs.ChatPaneBody)

    return  unless list and body

    list       = list.firstElementChild
    listHeight = list.offsetHeight
    bodyHeight = body.offsetHeight

    if (listHeight > bodyHeight)
    then list.classList.remove 'padded'
    else list.classList.add 'padded'


  onSubmit: (event) -> @props.onSubmit? event


  getScrollProps: ->
    scrollDirection          : 'up'
    onScrollThresholdReached : @props.onScrollThresholdReached
    isDataLoading            : @props.thread.getIn ['flags', 'isMessagesLoading']


  renderBody: ->
    return null  unless @props.messages

    messages = @props.messages.sortBy (m) -> m?.get 'createdAt'

    <section className="ChatPane-body" ref="ChatPaneBody">
      <InfiniteScroll {...@getScrollProps()} ref="ChatList">
        <ChatList messages={messages} />
      </InfiniteScroll>
    </section>


  onFollowChannelButtonClick: ->

    ActivityFlux.actions.channel.followChannel @props.thread.getIn ['channel', 'id']


  renderFooter: ->

    isParticipant = @props.thread?.getIn ['channel', 'isParticipant']
    footerInnerComponent = if isParticipant is yes
    then <ChatInputWidget onSubmit={@bound 'onSubmit'} />
    else if isParticipant is no
      <div className="ChatPane-subscribeContainer">
        YOU NEED TO FOLLOW THIS CHANNEL TO JOIN CONVERSATION
        <button ref="button" className="Button Button-followChannel" onClick={@bound 'onFollowChannelButtonClick'}>FOLLOW CHANNEL</button>
      </div>

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


