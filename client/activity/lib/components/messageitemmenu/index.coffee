kd                   = require 'kd'
React                = require 'kd-react'
checkFlag            = require 'app/util/checkFlag'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
getMessageOwner      = require 'app/util/getMessageOwner'
ActivityFlux         = require 'activity/flux'
AppFlux              = require 'app/flux'
immutable            = require 'immutable'
whoami               = require 'app/util/whoami'
remote               = require('app/remote').getInstance()
BlockUserModal       = require 'app/components/blockusermodal'
ActivityPromptModal  = require 'app/components/activitypromptmodal'
MarkUserAsTrollModal = require 'app/components/markuserastrollmodal'

module.exports = class MessageItemMenu extends React.Component

  @defaultProps =
    message : immutable.Map()

  constructor: (props) ->

    super props

    @state =
      account                       : null
      isDeleting                    : no
      isBlockUserModalVisible       : no
      isMarkUserAsTrollModalVisible : no


  componentDidMount: -> @getAccountInfo()


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


  getMenuItems: ->

    if checkFlag('super-admin')
    then @getAdminMenuItems()
    else @getDefaultMenuItems()


  getDefaultMenuItems: -> []

    return [
      {title: 'Edit Post'  , key: 'editpost'            , onClick: @bound 'editPost'}
      {title: 'Delete Post', key: 'showdeletepostprompt', onClick: @bound 'showDeletePostPromptModal'}
    ]


  getAdminMenuItems: ->

    { message } = @props
    markUserMenuItem =
      key: 'markuserastroll',
      title: 'Mark User as Troll',
      onClick: @bound 'showMarkUserAsTrollPromptModal'

    getMessageOwner message.toJS(), (err, owner) =>

      return showErrorNotification err  if err

      if owner.isExempt
        markUserMenuItem =
          key: 'unmarkuserastroll',
          title: 'Unmark User as Troll',
          onClick: @bound 'unMarkUserAsTroll'

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


  render: ->

    { message } = @props

    return null unless message

    if (message.get('accountId') is whoami().socialApiId) or checkFlag('super-admin')
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
