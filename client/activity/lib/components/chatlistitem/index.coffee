kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ActivityPromptModal  = require 'app/components/activitypromptmodal'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
keycode              = require 'keycode'
ActivityFlux         = require 'activity/flux'
classnames           = require 'classnames'
Portal               = require 'react-portal'


module.exports = class ChatListItem extends React.Component

  @defaultProps =
    hover      : no
    editMode   : no
    isDeleting : no
    isMenuOpen : no

  constructor: (props) ->

    super props

    @state =
      hover      : @props.hover
      editMode   : @props.editMode
      isDeleting : @props.isDeleting
      isMenuOpen : @props.isMenuOpen


  isEditedMessage: ->

    createdAt = @props.message.get 'createdAt'
    updatedAt = @props.message.get 'updatedAt'

    return isEdited = if createdAt is updatedAt then no else yes


  getItemProps: ->
    key       : @props.message.get 'id'
    className : classnames
      'ChatItem': yes
      'mouse-enter': @state.hover
      'is-menuOpen': @state.isMenuOpen
    onMouseEnter: =>
      @setState hover: yes
    onMouseLeave: =>
      @setState hover: no


  getMenuItems: ->
    return [
      {title: 'Edit Post',          key: 'editpost',    onClick: @bound 'editPost'}
      {title: 'Delete Post',        key: 'deletepost',  onClick: @bound 'deletePost'}
      {title: 'Mark User as Troll', key: 'markuser',    onClick: @bound 'markUser'}
      {title: 'Block User',         key: 'blockuser',   onClick: @bound 'blockUser'}
      {title: 'impersonate User',   key: 'impersonate', onClick: @bound 'impersonate'}
    ]


  getDeleteItemModalProps: ->
    title              : 'Delete post'
    body               : 'Are you sure you want to delete this post?'
    buttonConfirmTitle : 'DELETE'
    buttonAbortTitle   : 'CANCEL'
    onConfirm          : @bound 'deletePostButtonHandler'
    onAbort            : @bound 'closeDeletePostModal'
    onClose            : @bound 'closeDeletePostModal'


  deletePostButtonHandler: ->

    ActivityFlux.actions.message.removeMessage @props.message.get('id')
    @closeDeletePostModal()


  closeDeletePostModal: ->

    @setState isDeleting: no


  editPost: ->

    @setState editMode: yes
    domNode = @refs.EditMessageTextarea.getDOMNode()
    kd.utils.wait 100, ->
      kd.utils.moveCaretToEnd domNode


  deletePost: ->

    @setState isDeleting: yes


  markUser: ->

    console.log "mark user clicked"


  blockUser: ->

    console.log "block user clicked"


  impersonate: ->

    console.log "impersonate clicked"


  updateMessage: ->

    @setState editMode: no
    messageBody = @refs.EditMessageTextarea.getDOMNode().value
    createdAt   = @props.message.get 'createdAt'
    ActivityFlux.actions.message.editMessage @props.message.get('id'), messageBody, createdAt


  cancelEdit: ->

    @setState editMode: no


  onMenuToggle: (isMenuOpen) -> @setState { isMenuOpen }


  handleEditMessageKeyDown: (event) ->

    code = event.which or event.keyCode
    key  = keycode code
    @setState editMode: no if key is 'esc'

    if key is 'enter'
      @setState editMode: no
      ActivityFlux.actions.message.editMessage @props.message.get('id'), event.target.value


  getEditModeClassNames: -> classnames
    'ChatItem-updateMessageForm': yes
    'hidden' : not @state.editMode


  getMediaObjectClassNames: -> classnames
    'MediaObject-content': yes
    'hidden' : @state.editMode


  getContentClassNames: -> classnames
    'ChatItem-contentWrapper MediaObject': yes
    'editing': @state.editMode
    'edited' : @isEditedMessage()


  renderChatItemMenu: ->

    { message } = @props
    if message.get('accountId') is whoami().socialApiId
      <ButtonWithMenu
        items       = {@getMenuItems()}
        onMenuOpen  = {=> @onMenuToggle yes}
        onMenuClose = {=> @onMenuToggle no}
      />


  getClassNames: ->
    editForm: classnames
     'ChatItem-updateMessageForm': yes
     'hidden': not @state.editMode
    mediaContent: classnames
      'MediaObject-content': yes
      'hidden': @state.editMode
    contentWrapper: classnames
      'ChatItem-contentWrapper': yes
      'MediaObject': yes
      'editing': @state.editMode


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
            <MessageTime date={message.get 'createdAt'}/>
            <ActivityLikeLink messageId={message.get('id')} interactions={message.get('interactions').toJS()}/>
          </div>
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
        <div className={@getEditModeClassNames()}>
          <textarea autoFocus onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' } ref="EditMessageTextarea"></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        {@renderChatItemMenu()}
        <div className={@getClassNames().editForm}>
          <textarea
            onKeyDown={@bound 'handleEditMessageKeyDown'}
            defaultValue={message.get 'body'}
            ref="EditMessageTextarea">
          </textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'}>DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
          Are you sure you want to delete this post?
        </ActivityPromptModal>
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

