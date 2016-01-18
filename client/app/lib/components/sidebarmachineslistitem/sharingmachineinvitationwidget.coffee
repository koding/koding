React                    = require 'kd-react'
ReactDOM                 = require 'react-dom'
actions                  = require 'app/flux/environment/actions'
SidebarWidget            = require './sidebarwidget'
InvitationWidgetUserPart = require './invitationwidgetuserpart'

module.exports = class SharingMachineInvitationWidget extends React.Component

  coordinates:
    top : 0
    left: 0

  onRejectClicked: ->

    actions.setActiveInvitationMachineId { machine: null }
    actions.rejectInvitation @props.machine


  onAcceptClicked: ->

    actions.setActiveInvitationMachineId { machine: null }
    actions.acceptInvitation @props.machine


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
    then 'collaboration'
    else 'share'
    text = "wants to #{type} their VM with you."

    <SidebarWidget {...@props} coordinates={coordinates}>
      <InvitationWidgetUserPart
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
