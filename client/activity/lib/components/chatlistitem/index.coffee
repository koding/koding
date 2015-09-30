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
MessageLink           = require 'activity/components/publicchannelmessagelink'
EmbedBox              = require 'activity/components/embedbox'
KeyboardKeys          = require 'app/util/keyboardKeys'

module.exports = class ChatListItem extends React.Component

  @include [ImmutableRenderMixin]

  @defaultProps =
    hover                         : no
    account                       : null
    isDeleting                    : no
    isMenuOpen                    : no
    channelName                   : ''
    editInputValue                : ''
    isUserMarkedAsTroll           : no
    isBlockUserModalVisible       : no
    isMarkUserAsTrollModalVisible : no
    showItemMenu                  : yes
    isSelected                    : no

  constructor: (props) ->

    super props

    @state =
      hover                         : @props.hover
      account                       : @props.account
      editMode                      : @props.message.get '__isEditing'
      isDeleting                    : @props.isDeleting
      isMenuOpen                    : @props.isMenuOpen
      editInputValue                : @props.message.get 'body'
      isUserMarkedAsTroll           : @props.message.get('account').isExempt
      isBlockUserModalVisible       : @props.isBlockUserModalVisible
      isMarkUserAsTrollModalVisible : @props.isMarkUserAsTrollModalVisible


  componentDidMount: ->

    @getAccountInfo()


  componentDidUpdate: (prevProps, prevState) ->

    isEditing  = @props.message.get '__isEditing'
    wasEditing = prevProps.message.get '__isEditing'

    @focusInputOnEdit()  if isEditing and not wasEditing


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
      'mouse-enter'   : @state.hover
      'is-menuOpen'   : @state.isMenuOpen
      'is-selected'   : @props.isSelected
    onMouseEnter      : =>
      @setState hover : yes
    onMouseLeave      : =>
      @setState hover : no


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


  deletePostButtonHandler: ->

    ActivityFlux.actions.message.removeMessage @props.message.get('id')
    @closeDeletePostModal()


  closeDeletePostModal: ->

    @setState isDeleting: no


  focusInputOnEdit: ->

    domNode = @refs.EditMessageTextarea.getDOMNode()

    kd.utils.wait 100, ->
      kd.utils.moveCaretToEnd domNode


  editPost: ->

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.setMessageEditMode messageId


  showDeletePostPromptModal: ->

    @setState isDeleting: yes


  showMarkUserAsTrollPromptModal: ->

    @setState isMarkUserAsTrollModalVisible: yes


  closeMarkUserAsTrollModal: ->

    @setState isMarkUserAsTrollModalVisible: no


  closeBlockUserPromptModal: ->

    @setState isBlockUserModalVisible: no


  unMarkUserAsTroll: ->

    AppFlux.actions.user.unmarkUserAsTroll @state.account
    @closeMarkUserAsTrollModal()


  showBlockUserPromptModal: ->

    @setState isBlockUserModalVisible: yes


  impersonateUser: ->

    { message } = @props

    AppFlux.actions.user.impersonateUser message.toJS()


  updateMessage: ->

    return @deletePostButtonHandler()  if @state.isDeleting

    return @setState isDeleting: yes  unless @state.editInputValue.trim()

    name  = @props.channelName
    value = @state.editInputValue
    messageId = @props.message.get '_id'

    unless value.match ///\##{name}///
      value += " ##{name} "

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

    @setState editInputValue: @props.message.get('body')


  onMenuToggle: (isMenuOpen) -> @setState { isMenuOpen }


  onEditInputChange: (event) ->

    @setState { editInputValue: event.target.value }


  onEditInputKeyDown: (event) ->

    { ESC, ENTER } = KeyboardKeys

    switch event.which
      when ESC         then @cancelEdit()
      when ENTER       then @updateMessage()


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

    <div className={@getEditModeClassNames()}>
      <span className="ChatItem-authorName">
        {makeProfileLink message.get 'account'}
      </span>
      <div className="ChatItem-editActions">
        <button className="ChatItem-editAction submit" onClick={@bound 'updateMessage'}>enter to save</button>
        <button className="ChatItem-editAction cancel" onClick={@bound 'cancelEdit'}>esc to cancel</button>
      </div>
      <textarea
        autoFocus
        onKeyDown={@bound 'onEditInputKeyDown'}
        onChange={@bound 'onEditInputChange'}
        value={@state.editInputValue}
        ref="EditMessageTextarea"></textarea>
    </div>


  renderChatItemMenu: ->

    return null  unless @props.showItemMenu

    { message } = @props
    if (message.get('accountId') is whoami().socialApiId) or checkFlag('super-admin')
      <ButtonWithMenu
        items       = {@getMenuItems()}
        onMenuOpen  = {=> @onMenuToggle yes}
        onMenuClose = {=> @onMenuToggle no}
      />


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
            <MessageLink message={message} absolute={yes}>
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

