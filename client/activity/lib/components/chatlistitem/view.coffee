kd                      = require 'kd'
React                   = require 'kd-react'
ReactDOM                = require 'react-dom'
Avatar                  = require 'app/components/profile/avatar'
immutable               = require 'immutable'
MessageBody             = require 'activity/components/common/messagebody'
ProfileText             = require 'app/components/profile/profiletext'
ProfileLinkContainer    = require 'app/components/profile/profilelinkcontainer'
ActivityLikeLink        = require 'activity/components/chatlistitem/activitylikelink'
MessageTime             = require 'activity/components/chatlistitem/messagetime'
classnames              = require 'classnames'
ImmutableRenderMixin    = require 'react-immutable-render-mixin'
EmbedBox                = require 'activity/components/embedbox'
ChatInputEmbedExtractor = require 'activity/components/chatinputembedextractor'
ChannelToken            = require 'activity/components/chatinputwidget/tokens/channeltoken'
EmojiToken              = require 'activity/components/chatinputwidget/tokens/emojitoken'
MentionToken            = require 'activity/components/chatinputwidget/tokens/mentiontoken'
Encoder                 = require 'htmlencode'
MessageLink             = require 'activity/components/messagelink'
MessageItemMenu         = require 'activity/components/messageitemmenu'

module.exports = class ChatListItemView extends React.Component

  @include [ImmutableRenderMixin]

  @propTypes =
    message         : React.PropTypes.instanceOf immutable.Map
    showItemMenu    : React.PropTypes.bool
    isSelected      : React.PropTypes.bool
    channelId       : React.PropTypes.string
    onSubmit        : React.PropTypes.func
    onCancelEdit    : React.PropTypes.func
    onCloseEmbedBox : React.PropTypes.func

  @defaultProps =
    message         : immutable.Map()
    showItemMenu    : yes
    isSelected      : no
    channelId       : ''
    onSubmit        : kd.noop
    onCancelEdit    : kd.noop
    onCloseEmbedBox : kd.noop


  isEditedMessage: ->

    createdAt = @props.message.get 'createdAt'
    updatedAt = @props.message.get 'updatedAt'

    return isEdited = if createdAt is updatedAt then no else yes


  getItemProps: ->

    { message, isSelected } = @props

    key               : message.get 'id'
    className         : classnames
      'ChatItem'      : yes
      'is-selected'   : isSelected
      'is-pending'    : message.get 'isFake'
    'data-message-id' : message.get 'id'


  getEditModeClassNames: -> classnames
    'ChatItem-updateMessageForm': yes
    'hidden' : not @props.message.get '__isEditing'
    'visible' : @props.message.get '__isEditing'


  getMediaObjectClassNames: -> classnames
    'ChatListItem-itemBodyContainer': yes
    'hidden' : @props.message.get '__isEditing'


  getContentClassNames: -> classnames
    'ChatItem-contentWrapper MediaObject': yes
    'editing': @props.message.get '__isEditing'
    'edited' : @isEditedMessage()


  renderEditMode: ->

    { message } = @props
    messageBody = Encoder.htmlDecode message.get 'body'

    return  unless message.get '__isEditing'

    <div className={@getEditModeClassNames()}>
      <span className="ChatItem-authorName">
        {makeProfileLink message.get 'account'}
      </span>
      <div className="ChatItem-editActions">
        <button className="ChatItem-editAction submit" onClick={@props.onSubmit}>enter to save</button>
        <button className="ChatItem-editAction cancel" onClick={@props.onCancelEdit}>esc to cancel</button>
      </div>
      <ChatInputEmbedExtractor
        messageId = { message.get 'id' }
        channelId = { @props.channelId }
        value     = { messageBody }
        onSubmit  = { @props.onSubmit }
        onEsc     = { @props.onCancelEdit }
        ref       = 'editInput'
        tokens    = { [ChannelToken, EmojiToken, MentionToken] }
      />
    </div>


  renderChatItemMenu: ->

    return null  unless @props.showItemMenu

    <MessageItemMenu ref='MessageItemMenu' message={@props.message} channelId={@props.channelId} />


  renderEmbedBox: ->

    { message } = @props
    embedData   = message.get 'link'

    onClose = if message.get('__isEditing') then @props.onCloseEmbedBox

    if embedData
      <EmbedBox data={embedData.toJS()} type='chat' onClose={onClose} />


  render: ->

    { message } = @props
    <div {...@getItemProps()}>
      <div className={@getContentClassNames()}>
        <div className="MediaObject-media">
          {makeAvatar message.get 'account'}
        </div>
        <div className={@getMediaObjectClassNames()}>
          <div className="ChatItem-contentHeader">
            <span className="ChatItem-authorName">
              {makeProfileLink message.get 'account'}
            </span>
            <MessageLink message={message}>
              <MessageTime className='ChatItem-messageDate' date={message.get 'createdAt'}/>
            </MessageLink>
            <ActivityLikeLink messageId={message.get('id')} interactions={message.get('interactions').toJS()}/>
          </div>
          <div className="ChatItem-contentBody">
            <MessageBody message={message} />
          </div>
        </div>
        {@renderEditMode()}
        {@renderEmbedBox()}
        {@renderChatItemMenu()}
      </div>
    </div>


makeProfileLink = (imAccount) ->

  <ProfileLinkContainer origin={imAccount.toJS()}>
    <ProfileText />
  </ProfileLinkContainer>


makeAvatar = (imAccount) ->

  <ProfileLinkContainer origin={imAccount.toJS()}>
    <Avatar className="ChatItem-Avatar" width={35} height={35} />
  </ProfileLinkContainer>
