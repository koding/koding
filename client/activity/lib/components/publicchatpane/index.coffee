kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'
ChatInputWidget = require 'activity/components/chatinputwidget'


module.exports = class PublicChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    padded   : no

  constructor: (props) ->

    super props

    @state =
      showIntegrationTooltip   : no
      showCollaborationTooltip : no


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
    kd.utils.defer => ActivityFlux.actions.message.loadMessages @channel('id'), { from, loadedWithScroll: yes }


  onFollowChannel: ->

    ActivityFlux.actions.channel.followChannel @channel 'id'


  afterInviteOthers: ->

    return  unless input = @refs.chatInputWidget

    input.focus()


  onLoadMore: ->

    messages = @props.thread.get 'messages'
    from     = messages.first().get 'createdAt'

    ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  renderFollowChannel: ->

    <div className="PublicChatPane-subscribeContainer">
      This is a preview of <strong>#{@channel 'name'}</strong>
      <button
        ref       = "button"
        className = "Button Button-followChannel"
        onClick   = { @bound 'onFollowChannel' }>
          Join
      </button>
    </div>


  renderFooter: ->

    return null  unless @props.thread?.get 'messages'

    footerInnerComponent = if @channel 'isParticipant'
    then <ChatInputWidget
           ref          = 'chatInputWidget'
           onSubmit     = { @bound 'onSubmit' }
           onCommand    = { @bound 'onCommand' }
           channelId    = { @channel 'id' }
           enableSearch = { yes }
         />
    else @renderFollowChannel()

    <footer className="PublicChatPane-footer">
      {footerInnerComponent}
    </footer>


  render: ->

    <ChatPane
      thread     = { @props.thread }
      className  = "PublicChatPane"
      onSubmit   = { @bound 'onSubmit' }
      onLoadMore = { @bound 'onLoadMore' }
      afterInviteOthers = {@bound 'afterInviteOthers'}>
      {@renderFooter()}
    </ChatPane>


