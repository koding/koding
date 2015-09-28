kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'
ChatInputWidget = require 'activity/components/chatinputwidget'



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


  onLoadMore: ->

    return  unless @props.messages.size
    return  if @props.thread.getIn ['flags', 'isMessagesLoading']

    from = @props.messages.first().get('createdAt')
    kd.utils.defer => ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  onFollowChannel: ->

    ActivityFlux.actions.channel.followChannel @channel 'id'


  renderFollowChannel: ->

    <div className="PublicChatPane-subscribeContainer">
      YOU NEED TO FOLLOW THIS CHANNEL TO JOIN CONVERSATION
      <button
        ref       = "button"
        className = "Button Button-followChannel"
        onClick   = { @bound 'onFollowChannel' }>
          FOLLOW CHANNEL
      </button>
    </div>


  renderFooter: ->

    return null  unless @props.messages

    { thread } = @props

    footerInnerComponent = if @channel 'isParticipant'
    then <ChatInputWidget onSubmit={@bound 'onSubmit'} thread= {thread} enableSearch={yes} />
    else @renderFollowChannel()

    <footer className="PublicChatPane-footer">
      {footerInnerComponent}
    </footer>


  render: ->

    <ChatPane
      thread     = { @props.thread }
      className  = "PublicChatPane"
      messages   = { @props.messages }
      onSubmit   = { @bound 'onSubmit' }
      onLoadMore = { @bound 'onLoadMore' }
    >
      {@renderFooter()}
    </ChatPane>


