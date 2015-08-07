kd              = require 'kd'
React           = require 'kd-react'
ChatList        = require 'activity/components/chatlist'
InfiniteScroll  = require 'app/components/infinitescroll'
ChatInputWidget = require 'activity/components/chatinputwidget'



module.exports = class ChatPane extends React.Component

  @defaultProps =
    title                    : null
    messages                 : null
    isDataLoading            : no
    onScrollThresholdReached : kd.noop


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


  renderFooter: ->

    <footer className="ChatPane-footer">
      <ChatInputWidget onSubmit={@bound 'onSubmit'} />
    </footer>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        {@renderBody()}
        {@renderFooter()}
      </section>
    </div>


