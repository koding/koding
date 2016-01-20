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
ActivityFlux            = require 'activity/flux'
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

module.exports = class ChatListItem extends React.Component

  @include [ImmutableRenderMixin]

  @defaultProps =
    hover         : no
    isDeleting    : no
    channelName   : ''
    showItemMenu  : yes
    isSelected    : no
    channelId     : ''
    onEditStarted : kd.noop

  constructor: (props) ->

    super props

    @state =
      hover      : @props.hover
      editMode   : @props.message.get '__isEditing'
      isDeleting : @props.isDeleting


  componentDidUpdate: (prevProps, prevState) ->

    isInEditMode  = @props.message.get '__isEditing'
    wasInEditMode = prevProps.message.get '__isEditing'

    @refs.editInput.focus()  if isInEditMode and not wasInEditMode


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
    'data-message-id' : message.get 'id'


  updateMessage: ->

    value = @refs.editInput.getValue().trim()

    unless value
      return @refs.MessageItemMenu.showDeletePostPromptModal()

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.unsetMessageEditMode messageId, @props.channelId
    ActivityFlux.actions.message.editMessage messageId, value


  cancelEdit: ->

    messageId = @props.message.get '_id'
    ActivityFlux.actions.message.unsetMessageEditMode messageId, @props.channelId, yes


  onEditStarted: ->

    element = ReactDOM.findDOMNode this
    @props.onEditStarted? element


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
        <button className="ChatItem-editAction submit" onClick={@bound 'updateMessage'}>enter to save</button>
        <button className="ChatItem-editAction cancel" onClick={@bound 'cancelEdit'}>esc to cancel</button>
      </div>
      <ChatInputEmbedExtractor
        messageId = { message.get 'id' }
        channelId = { @props.channelId }
        value     = { messageBody }
        onSubmit  = { @bound 'updateMessage' }
        onEsc     = { @bound 'cancelEdit' }
        ref       = 'editInput'
        tokens    = { [ChannelToken, EmojiToken, MentionToken] }
        onReady   = { @bound 'onEditStarted' }
      />
    </div>


  renderChatItemMenu: ->

    return null  unless @props.showItemMenu

    <MessageItemMenu ref='MessageItemMenu' message={@props.message} channelId={@props.channelId} />


  renderEmbedBox: ->

    { message } = @props
    embedData   = message.get 'link'

    { disableEditedEmbedPayload } = ActivityFlux.actions.message
    onClose = if message.get('__isEditing') then -> disableEditedEmbedPayload message.get('id')

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
