kd = require 'kd'
React = require 'app/react'

Tracker = require 'app/util/tracker'
ContentModal = require 'app/components/contentModal'
actions = require 'app/flux/environment/actions'

SidebarWidget = require './widget'
SidebarWidgetUser = require './widgetuser'
SidebarWidgetTitle = require './widgettitle'


module.exports = class LeavingWidget extends React.Component

  @defaultProps =
    className : 'Approved'

  onLeaveClick: ->

    modal = new ContentModal
      title   : 'Are you sure?'
      content : """
        <p class='text-center'>
          This will remove the shared VM from your sidebar. You won't be able to
          access it unless you are invited again.
        </p>
        """
      cssClass : 'content-modal'
      buttons :
        No         :
          title    : 'Cancel'
          cssClass : 'solid cancel medium'
          callback : ->
            modal.destroy()

        Yes        :
          title    : 'Yes'
          cssClass : 'solid medium'
          loader   : yes
          callback : =>
            actions.leaveMachine @props.machine
            @onClose()
            Tracker.track Tracker.VM_LEFT_SHARED
            modal.destroy()


  onClose: ->

    { sidebar } = kd.singletons

    sidebar.setLeaving null


  render: ->

    buttonText = if @props.machine.getType() is 'collaboration'
    then 'LEAVE SESSION'
    else 'LEAVE SHARED VM'

    <SidebarWidget {...@props} onClose={@bound 'onClose'}>
      <SidebarWidgetTitle children='Shared with you by' />
      <SidebarWidgetUser owner={@props.machine.getOwner()} />
      <Button onClick={@bound 'onLeaveClick'}>{buttonText}</Button>
    </SidebarWidget>


Button = ({ children, onClick }) ->
  <button className='kdbutton GenericButton' onClick={onClick}>
    <span className='button-title'>{children}</span>
  </button>
