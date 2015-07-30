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
whoami               = require 'app/util/whoami'


module.exports = class ChatListItem extends React.Component

  constructor: (props) ->

    @state = { hover: no, showMenuForMouseAction: no, editMode: no }


  isEditedMessage: ->

    createdAt = @props.message.get 'createdAt'
    updatedAt = @props.message.get 'updatedAt'

    return isEdited = if createdAt is updatedAt then no else yes


  getItemProps: ->
    key       : @props.message.get 'id'
    className : \
      if @state.hover
      then kd.utils.curry 'ChatItem mouse-enter', @props.className
      else kd.utils.curry 'ChatItem', @props.className
    onMouseEnter: =>
      @setState hover: yes

    onMouseLeave: =>
      @setState hover: no
      @setState showMenuForMouseAction: no


  getMenuItems: ->
    return [
      {title: 'Edit Post',          key: 'editpost',    onClick: @bound 'editPost'}
      {title: 'Delete Post',        key: 'deletepost',  onClick: @bound 'deletePost'}
      {title: 'Mark User as Troll', key: 'markuser',    onClick: @bound 'markUser'}
      {title: 'Block User',         key: 'blockuser',   onClick: @bound 'blockUser'}
      {title: 'impersonate User',   key: 'impersonate', onClick: @bound 'impersonate'}
    ]


  getDeleteItemModalProps: ->
    className          : 'activityDeleteItemModal'
    title              : 'Delete post'
    body               : 'Are you sure you want to delete this post?'
    buttonYESText      : 'DELETE'
    buttonNOText       : 'CANCEL'
    buttonYESHandler   : @bound 'deletePostButtonHandler'
    buttonNOHandler    : @bound 'closeDeletePostModal'
    buttonCloseHandler : @bound 'closeDeletePostModal'


  deletePostButtonHandler: ->

    ActivityFlux.actions.message.removeMessage @props.message.get('id')
    @closeDeletePostModal()


  closeDeletePostModal: ->

    @modalContainer.classList.add 'hidden'


  editPost: ->

    @setState editMode: yes


  deletePost: ->

    @modalContainer = document.getElementsByClassName("PublicChatPane-ModalContainer")[0]
    @modalContainer.classList.remove 'hidden'
    React.render <ActivityPromptModal {...@getDeleteItemModalProps()}/>, @modalContainer
    @setState showMenuForMouseAction: no


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


  handleEditMessageKeyDown: (event) ->

    code = event.which or event.keyCode
    key  = keycode code
    createdAt = @props.message.get 'createdAt'
    @setState editMode: no if key is 'esc'

    if key is 'enter'

      @setState editMode: no
      ActivityFlux.actions.message.editMessage @props.message.get('id'), event.target.value, createdAt


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
      <ButtonWithMenu items={@getMenuItems()} showMenuForMouseAction={@state.showMenuForMouseAction}/>


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
          <textarea onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' } ref="EditMessageTextarea"></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
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

