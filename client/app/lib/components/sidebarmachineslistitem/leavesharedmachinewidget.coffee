React                     = require 'kd-react'
Popover                   = require 'app/components/common/popover'
actions                   = require 'app/flux/environment/actions'
SidebarWidget             = require './sidebarwidget'
InvitationWidgetUserPart  = require './invitationwidgetuserpart'

module.exports = class LeaveSharedMachineWidget extends React.Component

  @defaultProps =
    className : 'Approved'


  onLeaveClicked: ->

    actions.rejectInvitation @props.machine


  render: ->

    buttonText = if @props.machine.get('type') is 'collaboration'
    then 'LEAVE SESSION'
    else 'LEAVE SHARED VM'

    <SidebarWidget {...@props}>
      <p className='SidebarWidget-Title'>Shared with you by</p>
      <InvitationWidgetUserPart
        owner={@props.machine.get 'owner'}
       />
      <button className='kdbutton solid medium red' onClick={@bound 'onLeaveClicked'}>
        <span className='button-title'>{buttonText}</span>
      </button>
    </SidebarWidget>

