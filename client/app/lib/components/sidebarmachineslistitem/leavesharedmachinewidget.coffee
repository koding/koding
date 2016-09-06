kd = require 'kd'
React                     = require 'kd-react'
actions                   = require 'app/flux/environment/actions'
SidebarWidget             = require './sidebarwidget'
InvitationWidgetUserPart  = require './invitationwidgetuserpart'
Tracker                   = require 'app/util/tracker'
ContentModal = require 'app/components/contentModal'
{ byId, REMOVE } = require 'app/redux/modules/bongo'

module.exports = class LeaveSharedMachineWidget extends React.Component

  @defaultProps =
    className : 'Approved'


  onLeaveClicked: ->

    modal = new ContentModal
      title   : 'Are you sure?'
      content : "<p class='text-center'>This will remove the shared VM from your sidebar. You won't be able to access it unless you are invited again.</p>"
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
            machine = byId('JMachine', @props.machine.get('_id'))(kd.singletons.store.getState())
            kd.singletons.store.dispatch {
              type: REMOVE.SUCCESS
              result: machine
            }
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
      <button className='kdbutton GenericButton' onClick={@bound 'onLeaveClicked'}>
        <span className='button-title'>{buttonText}</span>
      </button>
    </SidebarWidget>

