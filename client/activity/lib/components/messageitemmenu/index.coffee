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



  getBlockUserModalProps: ->

    account            : @state.account
    buttonConfirmTitle : "BLOCK USER"
    className          : "BlockUserModal"
    onAbort            : @bound "closeBlockUserPromptModal"
    onClose            : @bound "closeBlockUserPromptModal"

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
