React                     = require 'kd-react'
actions                   = require 'app/flux/environment/actions'
SidebarWidget             = require './sidebarwidget'
InvitationWidgetUserPart  = require './invitationwidgetuserpart'
Tracker                   = require 'app/util/tracker'
ContentModal = require 'app/components/contentModal'


module.exports = class LeaveSharedMachineWidget extends React.Component

  @defaultProps =
    className : 'Approved'


  onLeaveClicked: ->

    modal = new ContentModal
      title   : 'Are you sure?'
      content : "<p>This will remove the shared VM from your sidebar. If you want to get back to the collaboration session later, you will need to manually go to this session's URL.</p>"
      cssClass : 'content-modal'
      buttons :
        No         :
          title    : 'Cancel'
          cssClass : 'solid cancel medium'
          callback : -> modal.destroy()
        Yes        :
          title    : 'Yes'
          cssClass : 'solid medium'
          loader   : yes
          callback : =>
            actions.rejectInvitation @props.machine
            Tracker.track Tracker.VM_LEFT_SHARED
            modal.destroy()



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

