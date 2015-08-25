kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'


module.exports = class PublicChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()
    padded   : no


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onSubmit: ({ value }) ->

    return  unless body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body

    @moveScrollToBottom()


  moveScrollToBottom: ->

    ChatPaneWrapper = @refs.ChatPaneWrapper.getDOMNode()
    InfiniteScroll = ChatPaneWrapper.querySelector '.InfiniteScroll'
    InfiniteScroll.scrollTop = InfiniteScroll.scrollHeight


  onLoadMore: ->

    return  unless @props.messages.size
    return  if @props.thread.getIn ['flags', 'isMessagesLoading']

    from = @props.messages.first().get('createdAt')
    kd.utils.defer => ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  render: ->
    <ChatPane
      thread={@props.thread}
      className="PublicChatPane"
      messages={@props.messages}
      onSubmit={@bound 'onSubmit'}
      onLoadMore={@bound 'onLoadMore'}
      isParticipant={@channel 'isParticipant'}
    />


