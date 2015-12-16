React                     = require 'kd-react'
Popover                   = require 'app/components/common/popover'
actions                   = require 'app/flux/environment/actions'
SidebarWidget             = require './sidebarwidget'
InvitationWidgetUserView  = require './invitationwidgetuserview'
EnvironmentFlux           = require 'app/flux/environment'


module.exports = class SharingMachineInvitationWidget extends React.Component

  onRejectClicked: ->

    actions.rejectInvitation @props.machine


  onAcceptClicked: ->

    actions.acceptInvitation @props.machine


  render: ->

    type = if @props.machine.get('type') is 'collaboration'
    then 'collaboration'
    else 'share'
    text = "wants to #{type} their VM with you."

    <SidebarWidget {...@props}>
      <InvitationWidgetUserView
        owner={@props.machine.get 'owner'}
       />
      <p className='SidebarWidget-Title'>{text}</p>
      <button className='kdbutton solid medium red' onClick={@bound 'onRejectClicked'}>
        <span className='button-title'>REJECT</span>
      </button>
      <button className='kdbutton solid green medium' onClick={@bound 'onAcceptClicked'}>
        <span className='button-title'>ACCEPT</span>
      </button>
    </SidebarWidget>
