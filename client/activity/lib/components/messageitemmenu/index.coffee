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


  getBlockUserModalProps: ->

    account            : @state.account
    buttonConfirmTitle : "BLOCK USER"
    className          : "BlockUserModal"
    onAbort            : @bound "closeBlockUserPromptModal"
    onClose            : @bound "closeBlockUserPromptModal"


  getMenuItems: ->

    if checkFlag('super-admin')
    then @getAdminMenuItems()
    else @getDefaultMenuItems()

  render: ->

    { message } = @props

    return null unless message

    if (message.get('accountId') is whoami().socialApiId) or checkFlag('super-admin')
      <div className={@props.className}>
        <ButtonWithMenu items={@getMenuItems()} />
        <BlockUserModal
          {...@getBlockUserModalProps()}
          isOpen={@state.isBlockUserModalVisible} />
      </div>
