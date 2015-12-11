kd      = require 'kd'
React   = require 'kd-react'
Popover = require 'app/components/common/popover'
actions = require 'app/flux/environment/actions'


module.exports = class SharingMachineInvitationWidget extends React.Component

  onRejectClicked: ->

    actions.rejectInvitation @props.machine


  onAcceptClicked: ->

    actions.acceptInvitation @props.machine


  render: ->
    <Popover {...@props}>
      <div className="user-view"></div>
      <p className="title">wants to share their VM with you.</p>
      <button onClick={@bound 'onRejectClicked'}>REJECT</button>
      <button onClick={@bound 'onAcceptClicked'}>ACCEPT</button>
    </Popover>
