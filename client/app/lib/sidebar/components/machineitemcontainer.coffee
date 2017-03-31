debug = require('debug')('sidebar:machinecontainer')
kd = require 'kd'
{ findDOMNode } = require 'react-dom'
React = require 'app/react'

Machine = require 'app/remote-extensions/machine'
connectCompute = require 'app/providers/connectcompute'

MachineItem = require './machineitem'

# this is gonna connect our component with compute storage & controller.
connector = connectCompute({
  storage: ['machines']
  defaultProps: {
    percentage: 0
    status: ''
  }
  controllerEvents: {
    stack: {
      apply: ({ status, percentage }) -> { status, percentage }
    }
    machine: {
      public: ({ status, percentage }) -> { status, percentage }
    }
  }
})

# export connected class via connector.
module.exports = connector class MachineItemContainer extends React.Component

  shouldComponentUpdate: (nextProps) -> nextProps.machine?

  constructor: (props) ->

    super props

    { sidebar } = kd.singletons

    @sidebarSubscription = null

    @state = @transformSidebarState sidebar.getState()


  # converts state from sidebar to the state of this view.
  transformSidebarState: ({ selected, invitedId, leavingId, managedId }) ->

    { machine } = @props
    newState = {}

    debug 'sidebar update', {
      machineId: machine.getId()
      selected, invitedId, leavingId
    }

    newState =
      selected: selected.machineId is machine.getId()
      invited: invitedId is machine.getId()
      leaving: leavingId is machine.getId()
      managed: managedId is machine.getId()

    if @item and (newState.leaving or newState.invited)
      rect = findDOMNode(@item).getBoundingClientRect()
      newState['coordinates'] =
        top: rect.top
        left: rect.width + rect.left

    return newState


  onSidebarChange: (sidebarState) ->

    return  unless @props.machine

    @setState @transformSidebarState sidebarState


  componentDidMount: ->

    { sidebar } = kd.singletons

    @sidebarSubscription = sidebar.subscribeChange @bound 'onSidebarChange'


  componentWillUnmount: ->

    @sidebarSubscription?.cancel()
    @sidebarSubscription = null


  onMachineClick: (event) ->

    { router, sidebar } = kd.singletons

    if @props.machine.isApproved()
    then router.handleRoute @props.machine.getIDELink()
    else sidebar.setInvited @props.machine.getId()


  onSettingsClick: (event) ->

    { router, sidebar } = kd.singletons
    { machine } = @props

    if machine.isMine() or machine.getOldOwner()
    then router.handleRoute machine.getDashboardLink()
    else sidebar.setLeaving @props.machine.getId()


  render: ->

    # these are coming from connectCompute HOC.
    { machine, status, percentage } = @props

    { selected, invited, leaving, managed, coordinates } = @state

    <MachineItem itemDidMount={(item) => @item = item}

      machine={machine}
      hasSettings={hasSettings machine}

      status={status}
      percentage={percentage}
      hasProgress={hasProgress status, percentage}

      selected={selected}
      invited={invited}
      leaving={leaving}
      managed={managed}
      coordinates={coordinates}

      onSettingsClick={@bound 'onSettingsClick'}
      onMachineClick={@bound 'onMachineClick'}

    />


hasSettings = (machine) ->

  return machine.isApproved() or machine.isRunning() or machine.isStopped()


hasProgress = (status, percentage) ->

  return status in ['Building', 'Starting', 'Stopping', 'Terminating']
