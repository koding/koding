kd          = require 'kd'
React       = require 'app/react'
List        = require 'app/components/list'
MachineItemContainer = require '../machineslist/listitemcontainer'

module.exports = class ConnectedMachinesListView extends React.Component

  @propTypes =
    onChangeAlwaysOn    : React.PropTypes.func
    onChangePowerStatus : React.PropTypes.func
    onDetailOpen        : React.PropTypes.func
    onSharedWithUser    : React.PropTypes.func
    onUnsharedWithUser  : React.PropTypes.func

  @defaultProps =
    onChangeAlwaysOn    : kd.noop
    onChangePowerStatus : kd.noop
    onDetailOpen        : kd.noop
    onSharedWithUser    : kd.noop
    onUnsharedWithUser  : kd.noop


  onDisconnectVM: (machine) ->
    @props.onDisconnectVM machine


  onDetailOpen: (machine) ->
    @props.onDetailOpen machine


  onSharedWithUser: (machine, nickname) ->
    @props.onSharedWithUser machine, nickname


  onUnsharedWithUser: (machine, nickname) ->
    @props.onUnsharedWithUser machine, nickname


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.stack?.machines.length or 0


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { stack } = @props
    machine = stack.machines[rowIndex]

    <MachineItemContainer
      key={machine.getId()}
      stackId={stack.getId()}
      machineId={machine.getId()}
      shouldRenderDetails={yes}
      shouldRenderSpecs={yes}
      shouldRenderDisconnect={yes}
      shouldRenderSharing={yes}
      onDisconnectVM={@lazyBound 'onDisconnectVM', machine}
      onDetailOpen={@lazyBound 'onDetailOpen', machine}
      onSharedWithUser={@lazyBound 'onSharedWithUser', machine}
      onUnsharedWithUser={@lazyBound 'onUnsharedWithUser', machine}
    />


  renderEmptySectionAtIndex: -> <div>No connected machines.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewVMSection'
      rowClassName='stack'
    />
