kd      = require 'kd'
React   = require 'kd-react'
Popover = require 'app/components/common/popover'
actions = require 'app/flux/environment/actions'


module.exports = class LeaveSharedMachineWidget extends React.Component

  onLeaveClicked: ->

    actions.rejectInvitation @props.machine


  render: ->

    buttonText = if @props.machine.get('type') is 'collaboration'
    then 'LEAVE SESSION'
    else 'LEAVE SHARED VM'

    <Popover {...@props}>
      <div>
        <span>Shared with you by</span>
      </div>
      <div className="user-view"></div>
      <button onClick={@bound 'onLeaveClicked'}>{buttonText}</button>
    </Popover>