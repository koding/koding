kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
keycode              = require 'keycode'

module.exports = class ChatListItem extends React.Component
  constructor: (props) ->

    @state = { hover: no, showMenuForMouseAction: no, editMode: no }

  getItemProps: ->
    key       : @props.message.get 'id'
    className : if @state.hover then kd.utils.curry 'ChatItem mouse-enter', @props.className else kd.utils.curry 'ChatItem', @props.className
    onMouseEnter: =>
      @setState hover: yes

    onMouseLeave: =>
      @setState hover: no
      @setState showMenuForMouseAction: no

  getMenuItems: ->
    return [
      {title: 'Edit Post',   key: 'editpost',  onClick: @bound 'editPost'}
      {title: 'Delete Post', key: 'deletepost', onClick: @bound 'deletePost'}
      {title: 'Mark User as Troll', key: 'markuser', onClick: @bound 'markUser'}
      {title: 'Block User', key: 'blockuser', onClick: @bound 'blockUser'}
      {title: 'impersonate User', key: 'impersonate', onClick: @bound 'impersonate'}
    ]

  editPost: ->
    @setState editMode: yes

  deletePost: ->
    console.log "delete post clicked"

  markUser: ->
    console.log "mark user clicked"

  blockUser: ->
    console.log "block user clicked"

  impersonate: ->
    console.log "impersonate clicked"

  updateMessage: ->
    console.log "update message"

  cancelEdit: ->
    @setState editMode: no

  handleEditMessageKeyDown: (event) ->

    code = event.which or event.keyCode
    key  = keycode code

    @setState editMode: no if key is 'esc'
    @setState editMode: no if key is 'enter'


  render: ->
    { message } = @props
    editFormClass       = if @state.editMode then 'ChatItem-updateMessageForm' else 'ChatItem-updateMessageForm hidden'
    mediaContentClass   = if @state.editMode then 'MediaObject-content hidden' else 'MediaObject-content'
    contentWrapperClass = if @state.editMode then 'ChatItem-contentWrapper MediaObject editing' else 'ChatItem-contentWrapper MediaObject'
    <div {...@getItemProps()}>
      <div className={contentWrapperClass}>
        <div className="MediaObject-media">
          {makeAvatar message.get 'account'}
        </div>
        <div className={mediaContentClass}>
          <div className="ChatItem-contentHeader">
            <span className="ChatItem-authorName">
              {makeProfileLink message.get 'account'}
            </span>
            <MessageTime date={message.get 'createdAt'}/>
            <ActivityLikeLink />
          </div>
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
        <div className={editFormClass}>
          <textarea onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' }></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        <ButtonWithMenu items={@getMenuItems()} showMenuForMouseAction={@state.showMenuForMouseAction}/>
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


