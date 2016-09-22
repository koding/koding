kd          = require 'kd'
React       = require 'app/react'
List        = require 'app/components/list'
MachineItem = require '../machineslist/listitem'

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

    @props.onDetailOpen machine.get '_id'


  onSharedWithUser: (machine, nickname) ->

    @props.onSharedWithUser machine.get('_id'), nickname


  onUnsharedWithUser: (machine, nickname) ->

    @props.onUnsharedWithUser machine.get('_id'), nickname

  numberOfSections: -> 1


  numberOfRowsInSection: ->
    @props.stacks?.size and @props.stacks?.get(0).get('machines').length

  renderSectionHeaderAtIndex: -> null

  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = @props.stacks.get rowIndex

    return  unless stack

    machines = stack.get 'machines'
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) =>
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
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
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewVMSection'
      rowClassName='stack'
    />
