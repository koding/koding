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

module.exports = class ChatListItem extends React.Component

  @defaultProps =
    hover                         : no
    account                       : null
    editMode                      : no
    isDeleting                    : no
    isMenuOpen                    : no
    editInputValue                : ''
    isUserMarkedAsTroll           : no
    isBlockUserModalVisible       : no
    isMarkUserAsTrollModalVisible : no

  constructor: (props) ->

    super props

    @state =
      hover                         : @props.hover
      account                       : @props.account
      editMode                      : @props.editMode
      isDeleting                    : @props.isDeleting
      isMenuOpen                    : @props.isMenuOpen
      editInputValue                : @props.message.get 'body'
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

    if checkFlag('super-admin') then @getAdminMenuItems() else @getDefaultMenuItems()


  getDefaultMenuItems: ->

    return [
      {title: 'Edit Post',          key: 'editpost',              onClick: @bound 'editPost'}
      {title: 'Delete Post',        key: 'showdeletepostprompt',  onClick: @bound 'showDeletePostPromptModal'}
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
      {title: 'Block User',         key: 'blockuser',   onClick: @bound 'showBlockUserPromptModal'}
      {title: 'Impersonate User',   key: 'impersonateuser', onClick: @bound 'impersonateUser'}
    ]

    return @getDefaultMenuItems().concat adminMenuItems


  getDeleteItemModalProps: ->

    title              : "Delete post"
    body               : "Are you sure you want to delete this post?"
    buttonConfirmTitle : "DELETE"
    buttonAbortTitle   : "CANCEL"
    className          : "Modal-DeleteItemPrompt"
    onConfirm          : @bound "deletePostButtonHandler"
    onAbort            : @bound "closeDeletePostModal"
    onClose            : @bound "closeDeletePostModal"


  getMarkUserAsTrollModalProps: ->

    account            : @state.account
    onAbort            : @bound "closeMarkUserAsTrollModal"
    onClose            : @bound "closeMarkUserAsTrollModal"


  getBlockUserModalProps: ->

    account            : @state.account
    buttonConfirmTitle : 'BLOCK USER'
    onAbort            : @bound "closeBlockUserPromptModal"
    onClose            : @bound "closeBlockUserPromptModal"


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

    @setState editMode: no

    ActivityFlux.actions.message.editMessage(
      @props.message.get('id')
      @state.editInputValue
      @props.message.get('payload').toJS()
    )


  cancelEdit: ->

    @setState editMode: no, editInputValue: @props.message.get('body')


  onMenuToggle: (isMenuOpen) -> @setState { isMenuOpen }


  onEditInputChange: (event) ->

    @setState { editInputValue: event.target.value }


  onEditInputKeyDown: (event) ->

    code = event.which or event.keyCode
    key  = keycode code

    switch key
      when 'esc'
        @cancelEdit()
      when 'enter'
        @updateMessage()


  getEditModeClassNames: -> classnames
    'ChatItem-updateMessageForm': yes
    'hidden' : not @state.editMode


  getMediaObjectClassNames: -> classnames
    'hidden' : @state.editMode


  getContentClassNames: -> classnames
    'ChatItem-contentWrapper MediaObject': yes
    'editing': @state.editMode
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

    { message } = @props
    if (message.get('accountId') is whoami().socialApiId) or checkFlag('super-admin')
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
      'hidden': @state.editMode
    contentWrapper: classnames
      'ChatItem-contentWrapper': yes
      'MediaObject': yes
      'editing': @state.editMode


  onKeyUpBlockingUserTime: (event)->

    @changeButtonTitle event.target.value


  changeButtonTitle: (value)->

    blockingTime = @calculateBlockingTime value
    if blockingTime > 0
      date = new Date (Date.now() + blockingTime)
      @setState blockUserConfirmButtonTitle: "Block until: #{date.toUTCString()}"
    else
      @setState blockUserConfirmButtonTitle: "Block User"


  calculateBlockingTime: (value)->

    totalTimestamp = 0
    unless value then return totalTimestamp
    for val in value.split(" ")
      # this is the first part of blocking time
      # if val 2D then numericalValue will be 2
      numericalValue = parseInt(val.slice(0, -1), 10) or 0
      if numericalValue is 0 then continue
      hour = numericalValue * 60 * 60 * 1000
      # we will get the lastest part of val as time case
      timeCase = val.charAt(val.length-1)
      switch timeCase.toUpperCase()
        when "S"
          totalTimestamp = 1000 # millisecond
        when "H"
          totalTimestamp = hour
        when "D"
          totalTimestamp = hour * 24
        when "W"
          totalTimestamp = hour * 24 * 7
        when "M"
          totalTimestamp = hour * 24 * 30
        when "Y"
          totalTimestamp = hour * 24 * 365

    return totalTimestamp

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
        {@renderEditMode()}
        {@renderChatItemMenu()}
        <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
          Are you sure you want to delete this post?
        </ActivityPromptModal>
        <ActivityPromptModal {...@getMarkUserAsTrollModalProps()} isOpen={@state.isMarkUserAsTrollModalVisible}>
          This is what we call 'Trolling the troll' mode.<br/><br/>
          All of the troll's activity will disappear from the feeds, but the troll himself will think that people still gets his posts/comments. <br/><br/>
          Are you sure you want to mark him as a troll?
        </ActivityPromptModal>
        <ActivityPromptModal {...@getBlockUserModalProps()} isOpen={@state.isBlockUserModalVisible}>
          This will block user from logging in to Koding(with all sub-groups).<br/><br/>
          You can specify a duration to block user.
          Entry format: [number][S|H|D|T|M|Y] eg. 1M<br/><br/>
          <div className="duration">
            <label className="block-user-for" for="duration">Block User For</label>
            <input name="duration" onKeyUp={@bound "onKeyUpBlockingUserTime"} onChange={@bound "onKeyUpBlockingUserTime"} type="text" ref="BlockingTimeInput" placeholder="e.g. 1Y 1W 3D 2H..."/>
          </div>
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

