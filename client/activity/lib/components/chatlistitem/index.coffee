kd                    = require 'kd'
React                 = require 'kd-react'
remote                = require('app/remote').getInstance()
Avatar                = require 'app/components/profile/avatar'
immutable             = require 'immutable'
MessageBody           = require 'activity/components/common/messagebody'
ProfileText           = require 'app/components/profile/profiletext'
ProfileLinkContainer  = require 'app/components/profile/profilelinkcontainer'
ButtonWithMenu        = require 'app/components/buttonwithmenu'
ActivityPromptModal   = require 'app/components/activitypromptmodal'
MarkUserAsTrollModal  = require 'app/components/markuserastrollmodal'
BlockUserModal        = require 'app/components/blockusermodal'
ActivityLikeLink      = require 'activity/components/chatlistitem/activitylikelink'
MessageTime           = require 'activity/components/chatlistitem/messagetime'
keycode               = require 'keycode'
AppFlux               = require 'app/flux'
ActivityFlux          = require 'activity/flux'
classnames            = require 'classnames'
Portal                = require 'react-portal'
whoami                = require 'app/util/whoami'
checkFlag             = require 'app/util/checkFlag'
impersonate           = require 'app/util/impersonate'
getMessageOwner       = require 'app/util/getMessageOwner'
showErrorNotification = require 'app/util/showErrorNotification'
showNotification      = require 'app/util/showNotification'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'
EmbedBox              = require 'activity/components/embedbox'
KeyboardKeys          = require 'app/util/keyboardKeys'
ChatInputWidget       = require 'activity/components/chatinputwidget'
Encoder               = require 'htmlencode'
MessageLink           = require 'activity/components/messagelink'

module.exports = class ChatListItem extends React.Component

  @include [ImmutableRenderMixin]

  @defaultProps =
    hover                         : no
    account                       : null
    isDeleting                    : no
    channelName                   : ''
    isUserMarkedAsTroll           : no
    isBlockUserModalVisible       : no
    isMarkUserAsTrollModalVisible : no
    showItemMenu                  : yes
    isSelected                    : no
    channelId                     : ''
    onEditStarted                 : kd.noop

  constructor: (props) ->

    super props

    @state =
      hover                         : @props.hover
      account                       : @props.account
      editMode                      : @props.message.get '__isEditing'
      isDeleting                    : @props.isDeleting
      isUserMarkedAsTroll           : @props.message.get('account').isExempt
      isBlockUserModalVisible       : @props.isBlockUserModalVisible
      isMarkUserAsTrollModalVisible : @props.isMarkUserAsTrollModalVisible


  componentDidMount: ->

    @getAccountInfo()


  getAccountInfo: ->

    { message } = @props
    message = message.toJS()

    if message.account._id
      remote.cacheable "JAccount", message.account._id, (err, account)=>
        return @setState account: account  if account
    else if message.bongo_.constructorName is 'JAccount'
      return @setState account: message  if account


  isEditedMessage: ->

    createdAt = @props.message.get 'createdAt'
    updatedAt = @props.message.get 'updatedAt'

    return isEdited = if createdAt is updatedAt then no else yes


  getItemProps: ->

    key               : @props.message.get 'id'
    className         : classnames
      'ChatItem'      : yes
      'is-selected'   : @props.isSelected

  getMenuItems: ->

    if checkFlag('super-admin')
    then @getAdminMenuItems()
    else @getDefaultMenuItems()


  getDefaultMenuItems: ->

    return [
      {title: 'Edit Post'   , key: 'editpost'             , onClick: @bound 'editPost'}
      {title: 'Delete Post' , key: 'showdeletepostprompt' , onClick: @bound 'showDeletePostPromptModal'}
    ]


  getAdminMenuItems: ->

    { message } = @props
    markUserMenuItem = {title: 'Mark User as Troll', key: 'markuserastroll', onClick: @bound 'showMarkUserAsTrollPromptModal'}

    getMessageOwner message.toJS(), (err, owner) =>

      return showErrorNotification err  if err

      if owner.isExempt
        markUserMenuItem = {title: 'Unmark User as Troll', key: 'unmarkuserastroll', onClick: @bound 'unMarkUserAsTroll'}

    adminMenuItems = [
      markUserMenuItem
      {
        title   : 'Block User'
        key     : 'blockuser'
        onClick : @bound 'showBlockUserPromptModal'
      }
      {
        title   : 'Impersonate User'
        key     : 'impersonateuser'
        onClick : @bound 'impersonateUser'
      }
    ]

    return @getDefaultMenuItems().concat adminMenuItems


  getDeleteItemModalProps: ->

    title              : "Delete post"
    body               : "Are you sure you want to delete this post?"
    buttonConfirmTitle : "DELETE"
    className          : "Modal-DeleteItemPrompt"
    onConfirm          : @bound "deletePostButtonHandler"
    onAbort            : @bound "closeDeletePostModal"
    onClose            : @bound "closeDeletePostModal"


  getMarkUserAsTrollModalProps: ->

    account            : @state.account
    title              : "MARK USER AS TROLL"
    className          : "MarkUserAsTrollModal"
    onAbort            : @bound "closeMarkUserAsTrollModal"
    onClose            : @bound "closeMarkUserAsTrollModal"
    buttonConfirmTitle : "YES, THIS USER IS DEFINITELY A TROLL"


  getBlockUserModalProps: ->

    account            : @state.account
    buttonConfirmTitle : "BLOCK USER"
    className          : "BlockUserModal"
    onAbort            : @bound "closeBlockUserPromptModal"
    onClose            : @bound "closeBlockUserPromptModal"


  deletePostButtonHandler: (event) ->

    kd.utils.stopDOMEvent event
    ActivityFlux.actions.message.removeMessage @props.message.get('id')
    @closeDeletePostModal()


  closeDeletePostModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isDeleting: no


  editPost: ->

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.setMessageEditMode messageId


  showDeletePostPromptModal: ->

    @setState isDeleting: yes


  showMarkUserAsTrollPromptModal: ->

    @setState isMarkUserAsTrollModalVisible: yes


  closeMarkUserAsTrollModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isMarkUserAsTrollModalVisible: no


  closeBlockUserPromptModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isBlockUserModalVisible: no


  unMarkUserAsTroll: (event) ->

    kd.utils.stopDOMEvent event
    AppFlux.actions.user.unmarkUserAsTroll @state.account
    @closeMarkUserAsTrollModal()


  showBlockUserPromptModal: ->

    @setState isBlockUserModalVisible: yes


  impersonateUser: (event) ->

    kd.utils.stopDOMEvent event
    { message } = @props

    AppFlux.actions.user.impersonateUser message.toJS()


  updateMessage: ->

    return @deletePostButtonHandler()  if @state.isDeleting

    value = @refs.editInput.getValue().trim()
    return @setState isDeleting: yes  unless value

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.unsetMessageEditMode messageId

    ActivityFlux.actions.message.editMessage(
      @props.message.get('id')
      value
      @props.message.get('payload').toJS()
    )


  cancelEdit: ->

    return @closeDeletePostModal()  if @state.isDeleting

    messageId = @props.message.get '_id'
    ActivityFlux.actions.message.unsetMessageEditMode messageId


  onEditStarted: ->

    element = React.findDOMNode this
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
      <ChatInputWidget
        channelId        = { @props.channelId }
        value            = { messageBody }
        onSubmit         = { @bound 'updateMessage' }
        onEsc            = { @bound 'cancelEdit' }
        ref              = 'editInput'
        disabledFeatures = { ['commands'] }
        onReady          = { @bound 'onEditStarted' }
      />
    </div>


  renderChatItemMenu: ->

    return null  unless @props.showItemMenu

    { message } = @props
    if (message.get('accountId') is whoami().socialApiId) or checkFlag('super-admin')
      <ButtonWithMenu items={@getMenuItems()} />


  renderEmbedBox: ->

    { message } = @props
    embedData   = message.get 'link'

    if embedData
      <EmbedBox data={embedData.toJS()} type='chat' />


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
              <MessageTime date={message.get 'createdAt'}/>
            </MessageLink>
            <ActivityLikeLink messageId={message.get('id')} interactions={message.get('interactions').toJS()}/>
          </div>
          <div className="ChatItem-contentBody">
            <MessageBody message={message} />
          </div>
          {@renderEmbedBox()}
        </div>
        {@renderEditMode()}
        {@renderChatItemMenu()}
        <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
          Are you sure you want to delete this post?
        </ActivityPromptModal>
        <MarkUserAsTrollModal {...@getMarkUserAsTrollModalProps()} isOpen={@state.isMarkUserAsTrollModalVisible} />
        <BlockUserModal {...@getBlockUserModalProps()} isOpen={@state.isBlockUserModalVisible} />
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

