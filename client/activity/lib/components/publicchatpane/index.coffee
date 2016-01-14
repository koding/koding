kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
ActivityFlux         = require 'activity/flux'
ChatPane             = require 'activity/components/chatpane'
ChatInputWidget      = require 'activity/components/chatinputwidget'
ChannelToken         = require 'activity/components/chatinputwidget/tokens/channeltoken'
EmojiToken           = require 'activity/components/chatinputwidget/tokens/emojitoken'
MentionToken         = require 'activity/components/chatinputwidget/tokens/mentiontoken'
SearchToken          = require 'activity/components/chatinputwidget/tokens/searchtoken'
CommandToken         = require 'activity/components/chatinputwidget/tokens/commandtoken'
ChatPaneWrapperMixin = require 'activity/components/chatpane/chatpanewrappermixin'
FollowChannelBox     = require 'activity/components/followchannelbox'

{ message: messageActions, command: commandActions } = ActivityFlux.actions

module.exports = class PublicChatPane extends React.Component

  @propTypes =
    thread : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    thread : immutable.Map()


  channel: (keyPath...) -> @props.thread?.getIn ['channel'].concat keyPath


  onSubmit: ({ value }) ->

    return  unless value

    messageActions.createMessage @channel('id'), value


  onCommand: ({ command }) -> commandActions.executeCommand command, @channel()


  onLoadMore: ->

    return  unless (messages = @props.thread.get 'messages').size

    messageActions.loadMessages @channel('id'),
      from: messages.first().get 'createdAt'


  onInviteClick: ->

    return  unless input = @refs.chatInputWidget

    input.setCommand '/invite @'


  renderFooter: ->

    return null  unless @props.thread?.get 'messages'

    isParticipant = @channel 'isParticipant'

    <footer className="PublicChatPane-footer ChatPaneFooter">
      <ChatInputWidget.Container
        ref       = 'chatInputWidget'
        className = { unless isParticipant then 'hidden' }
        onSubmit  = { @bound 'onSubmit' }
        onCommand = { @bound 'onCommand' }
        channelId = { @channel 'id' }
        onResize  = { @bound 'onResize' }
        tokens    = { [ChannelToken, EmojiToken, MentionToken, SearchToken, CommandToken] }
      />
      <FollowChannelBox
        className={if isParticipant then 'hidden'}
        thread={@props.thread} />
    </footer>


  render: ->

    return null  unless @props.thread

    <div>
      <ChatPane
        ref='chatPane'
        key={@props.thread.get 'channelId'}
        thread={@props.thread}
        className='PublicChatPane'
        onSubmit={@bound 'onSubmit'}
        onLoadMore={@bound 'onLoadMore'}
        onInviteClick={@bound 'onInviteClick'}
      />
      {@renderFooter()}
    </div>


PublicChatPane.include [ChatPaneWrapperMixin]
