debug = require('debug')('sidebar:machinecontainer')
kd = require 'kd'
{ findDOMNode } = require 'react-dom'
React = require 'app/react'

getMachineLinks = require 'app/util/getMachineLinks'

Machine = require 'app/remote-extensions/machine'
connectCompute = require 'app/providers/connectcompute'
connectSidebar = require 'app/sidebar/connectsidebar'

MachineItem = require './machineitem'

# this is gonna connect our component with compute storage & controller.
computeConnector = connectCompute({
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

sidebarConnector = connectSidebar({
  transformState: (sidebarState, props) ->

    { machine } = props

    unless machine
      return {
        selected: no
        invited: no
        leaving: no
        managed: no
      }

    { selected, invitedId, leavingId, managedId } = sidebarState

    debug 'sidebar update', {
      machineId: machine.getId(), selected, invitedId, leavingId
    }

    return {
      selected: selected.machineId is machine.getId()
      invited: invitedId is machine.getId()
      leaving: leavingId is machine.getId()
      managed: managedId is machine.getId()
    }
})

# export connected class via computeConnector.
module.exports = computeConnector sidebarConnector class MachineItemContainer extends React.Component

  shouldComponentUpdate: (nextProps) -> nextProps.machine?

  constructor: (props) ->

    super props

    @state = { coordinates: {} }

    @item = null


  componentDidMount: ->

    if @item and (@props.leaving or @props.invited or @props.managed)
      kd.utils.defer =>
        rect = findDOMNode(@item).getBoundingClientRect()

        @setState
          coordinates: { top: rect.top, left: rect.width + rect.left }


  componentWillReceiveProps: (nextProps) ->

    if @item and (nextProps.leaving or nextProps.invited or nextProps.managed)
      kd.utils.defer =>
        rect = findDOMNode(@item).getBoundingClientRect()

        @setState
          coordinates: { top: rect.top, left: rect.width + rect.left }


  onMachineClick: (event) ->

    { router, sidebar } = kd.singletons

    if @props.machine.isApproved()
    then router.handleRoute getMachineLinks @props.machine, 'ide'
    else sidebar.setInvited @props.machine.getId()


  onSettingsClick: (event) ->

    { router, sidebar } = kd.singletons
    { machine } = @props

    if machine.isMine() or machine.getOldOwner()
    then router.handleRoute getMachineLinks machine, 'dashboard'
    else sidebar.setLeaving @props.machine.getId()


  render: ->

    { machine, status, percentage
      selected, invited, leaving, managed } = @props

    { coordinates } = @state

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
