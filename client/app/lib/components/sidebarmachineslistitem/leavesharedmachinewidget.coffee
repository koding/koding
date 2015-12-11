React             = require 'kd-react'
Popover           = require 'app/components/common/popover'
actions           = require 'app/flux/environment/actions'
InvitationWidget  = require './invitationwidget'


module.exports = class LeaveSharedMachineWidget extends React.Component

  onLeaveClicked: ->

    actions.rejectInvitation @props.machine


  render: ->

    buttonText = if @props.machine.get('type') is 'collaboration'
    then 'LEAVE SESSION'
    else 'LEAVE SHARED VM'

    <InvitationWidget {...@props}>
      <p className='InvitationWidget-Title'>Shared with you by</p>
      <div className="user-view"></div>
      <button className='kdbutton solid medium red' onClick={@bound 'onLeaveClicked'}>
        <span className='button-title'>{buttonText}</span>
      </button>
    </InvitationWidget>
