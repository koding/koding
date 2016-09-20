kd = require 'kd'
React                    = require 'kd-react'
ReactDOM                 = require 'react-dom'
actions                  = require 'app/flux/environment/actions'
SidebarWidget            = require './sidebarwidget'
InvitationWidgetUserPart = require './invitationwidgetuserpart'
Tracker                  = require 'app/util/tracker'
{ byId, REMOVE, LOAD }  = require 'app/redux/modules/bongo'

module.exports = class SharingMachineInvitationWidget extends React.Component

  coordinates:
    top : 0
    left: 0

  onRejectClicked: ->

    actions.setActiveInvitationMachineId { machine: null }
    actions.rejectInvitation @props.machine
    machine = byId('JMachine', @props.machine.get('_id'))(kd.singletons.store.getState())
    kd.singletons.store.dispatch {
      type: REMOVE.SUCCESS
      result: machine
    }
    Tracker.track Tracker.VM_REJECTED_SHARED


  onAcceptClicked: ->

    actions.setActiveInvitationMachineId { machine: null }
    actions.acceptInvitation @props.machine

    machine = byId('JMachine', @props.machine.get('_id'))(kd.singletons.store.getState())

    kd.singletons.store.dispatch {
      type: LOAD.SUCCESS
      result: machine
    }

    Tracker.track Tracker.VM_ACCEPTED_SHARED


  componentDidUpdate: -> @setCoordinates()


  componentWillMount: -> @setCoordinates()


  setCoordinates: ->

    listItemNode = ReactDOM.findDOMNode @props.listItem

    if listItemNode
      clientRect    = listItemNode.getBoundingClientRect()
      { top, left, width } = clientRect
      left = left + width
      @coordinates = { top, left }


  render: ->

    coordinates = @coordinates

    return null  if not coordinates.top and not coordinates.left

    type = if @props.machine.get('type') is 'collaboration'
    then 'collaborate'
    else 'share'
    text = "wants to #{type} their VM with you."

    <SidebarWidget {...@props} coordinates={coordinates}>
      <InvitationWidgetUserPart
        owner={@props.machine.get 'owner'}
       />
      <p className='SidebarWidget-Title'>{text}</p>
      <div className='button-wrapper'>
        <button className='kdbutton GenericButton reject' onClick={@bound 'onRejectClicked'}>
          <span className='button-title'>REJECT</span>
        </button>
        <button className='kdbutton GenericButton accept' onClick={@bound 'onAcceptClicked'}>
          <span className='button-title'>ACCEPT</span>
        </button>
      </div>
    </SidebarWidget>
