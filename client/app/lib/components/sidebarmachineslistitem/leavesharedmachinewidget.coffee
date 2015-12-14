React             = require 'kd-react'
Popover           = require 'app/components/common/popover'
actions           = require 'app/flux/environment/actions'
InvitationWidget          = require './invitationwidget'
InvitationWidget          = require './invitationwidget'
InvitationWidgetUserView  = require './invitationwidgetuserview'


module.exports = class LeaveSharedMachineWidget extends React.Component

  @defaultProps =
    className : '--Approved'


  onLeaveClicked: ->

    actions.rejectInvitation @props.machine


  render: ->

    buttonText = if @props.machine.get('type') is 'collaboration'
    then 'LEAVE SESSION'
    else 'LEAVE SHARED VM'

    <InvitationWidget {...@props}>
      <p className='InvitationWidget-Title'>Shared with you by</p>
      <InvitationWidgetUserView
        owner={@props.machine.get 'owner'}
       />
      <button className='kdbutton solid medium red' onClick={@bound 'onLeaveClicked'}>
        <span className='button-title'>{buttonText}</span>
      </button>
    </InvitationWidget>
