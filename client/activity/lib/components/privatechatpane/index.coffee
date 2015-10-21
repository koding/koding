kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'
ChatInputWidget = require 'activity/components/chatinputwidget'

module.exports = class PrivateChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onSubmit: ({ value }) ->

    return  unless body = value

    ActivityFlux.actions.message.createMessage @channel('id'), body


  onCommand: ({ command }) ->

    ActivityFlux.actions.command.executeCommand command, @props.thread.get 'channel'


  onLoadMore: ->

    return  unless @props.messages.size
    return  if @props.thread.getIn ['flags', 'isMessagesLoading']

    from = @props.messages.first().get('createdAt')
    kd.utils.defer => ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  onInviteOthers: ->

    return  unless input = @refs.chatInputWidget

    input.setValue '/invite @'


  render: ->

    <ChatPane
      thread     = { @props.thread }
      className  = 'PrivateChatPane'
      messages   = { @props.messages }
      onSubmit   = { @bound 'onSubmit' }
      onInviteOthers = {@bound 'onInviteOthers'}
      onLoadMore = { @bound 'onLoadMore' }
    >
      <footer className='PrivateChatPane-footer'>
        <ChatInputWidget
          onSubmit         = { @bound 'onSubmit' }
          onCommand        = { @bound 'onCommand' }
          channelId        = { @channel 'id' }
          disabledFeatures = { ['search'] }
          ref              = 'chatInputWidget'
        />
      </footer>
    </ChatPane>


