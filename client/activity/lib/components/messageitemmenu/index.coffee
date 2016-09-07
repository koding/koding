kd                    = require 'kd'
React                 = require 'kd-react'
ButtonWithMenu        = require 'app/components/buttonwithmenu'
getMessageOwner       = require 'app/util/getMessageOwner'
ActivityFlux          = require 'activity/flux'
AppFlux               = require 'app/flux'
immutable             = require 'immutable'
whoami                = require 'app/util/whoami'
remote                = require('app/remote').getInstance()
BlockUserModal        = require 'app/components/blockusermodal'
ActivityPromptModal   = require 'app/components/activitypromptmodal'
MarkUserAsTrollModal  = require 'app/components/markuserastrollmodal'
showErrorNotification = require 'app/util/showErrorNotification'
hasPermission         = require 'app/util/hasPermission'

module.exports = class MessageItemMenu extends React.Component

  @defaultProps =
    disableAdminMenuItems : no
    message               : immutable.Map()
    channelId             : ''

  constructor: (props) ->

    super props

    @state =
      account                       : null
      isDeleting                    : no
      isOwnerExempt                 : no
      isBlockUserModalVisible       : no
      isMarkUserAsTrollModalVisible : no


  componentDidMount: ->

    @checkTheOwnerIsExempt()
    @getAccountInfo()


  checkTheOwnerIsExempt: ->

    getMessageOwner @props.message.toJS(), (err, owner) =>

      return showErrorNotification err  if err

      @setState isOwnerExempt: owner.isExempt


  getAccountInfo: ->

    message = @props.message.toJS()

    if message.account._id
      remote.cacheable "JAccount", message.account._id, (err, account)=>
        return @setState account: account  if account
    else if message.bongo_.constructorName is 'JAccount'
      return @setState account: message  if account


  showBlockUserPromptModal: ->

    @setState isBlockUserModalVisible: yes


  closeBlockUserPromptModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isBlockUserModalVisible: no


  showDeletePostPromptModal: ->

    @setState isDeleting: yes


  closeDeletePostModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isDeleting: no


  showMarkUserAsTrollPromptModal: ->

    @setState isMarkUserAsTrollModalVisible: yes


  closeMarkUserAsTrollModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isMarkUserAsTrollModalVisible: no


  unMarkUserAsTroll: (event) ->

    kd.utils.stopDOMEvent event
    AppFlux.actions.user.unmarkUserAsTroll @state.account
    @closeMarkUserAsTrollModal()


  editPost: ->

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.setMessageEditMode messageId, @props.channelId


  deletePostButtonHandler: (event) ->

    kd.utils.stopDOMEvent event
    ActivityFlux.actions.message.removeMessage @props.message.get('id')
    @closeDeletePostModal()


  impersonateUser: (event) ->

    kd.utils.stopDOMEvent event
    { message } = @props

    AppFlux.actions.user.impersonateUser message.toJS()


  getBlockUserModalProps: ->

    account            : @state.account
    buttonConfirmTitle : "BLOCK USER"
    className          : "BlockUserModal"
    onAbort            : @bound "closeBlockUserPromptModal"
    onClose            : @bound "closeBlockUserPromptModal"


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


  canEditPost: ->

    canEdit    = hasPermission 'edit posts'
    canEditOwn = hasPermission 'edit own posts'

    return canEdit or (canEditOwn and @isMyMessage())


  canDeletePost: ->

    canDelete    = hasPermission 'delete posts'
    canDeleteOwn = hasPermission 'delete own posts'

    return canDelete or (canDeleteOwn and @isMyMessage())


  isMyMessage: ->

    return @props.message.get('accountId') is whoami().socialApiId


  getMenuItems: ->

    result = []

    if @canEditPost() then result.push @getEditMenuItem()

    if @canDeletePost() then result.push @getDeleteMenuItem()

    return result


  getEditMenuItem: ->

    return {title: 'Edit Post'  , key: 'editpost'            , onClick: @bound 'editPost'}


  getDeleteMenuItem: ->

    return {title: 'Delete Post', key: 'showdeletepostprompt', onClick: @bound 'showDeletePostPromptModal'}


  render: ->

    { message } = @props

    return null  unless message

    return null  if not @canEditPost() or not @canDeletePost()

    <div className={@props.className}>
      <ButtonWithMenu items={@getMenuItems()} />
      <BlockUserModal
        {...@getBlockUserModalProps()}
        isOpen={@state.isBlockUserModalVisible} />
      <MarkUserAsTrollModal
        {...@getMarkUserAsTrollModalProps()}
        isOpen={@state.isMarkUserAsTrollModalVisible} />
      <ActivityPromptModal
        {...@getDeleteItemModalProps()}
        isOpen={@state.isDeleting}>
        Are you sure you want to delete this post?
      </ActivityPromptModal>
    </div>
