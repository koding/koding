kd              = require 'kd'
React           = require 'app/react'
List            = require 'app/components/list'
MachineItemContainer = require '../machineslist/listitemcontainer'


module.exports = class VirtualMachinesListView extends React.Component

  @propTypes =
    onChangeAlwaysOn    : React.PropTypes.func
    onChangePowerStatus : React.PropTypes.func
    onSharedWithUser    : React.PropTypes.func
    onUnsharedWithUser  : React.PropTypes.func
    onCancelSharing     : React.PropTypes.func

  @defaultProps =
    onChangeAlwaysOn    : kd.noop
    onChangePowerStatus : kd.noop
    onSharedWithUser    : kd.noop
    onUnsharedWithUser  : kd.noop
    onCancelSharing     : kd.noop


  onChangeAlwaysOn: (machine, state) ->

    @props.onChangeAlwaysOn machine, state


  onChangePowerStatus: (machine, shouldStart) ->

    @props.onChangePowerStatus machine, shouldStart


  onChangeSharingStatus: (machine, shouldShare) ->

    return  if shouldShare

    @props.onCancelSharing machine


  onSharedWithUser: (machine, nickname) ->

    @props.onSharedWithUser machine, nickname


  onUnsharedWithUser: (machine, nickname) ->

    @props.onUnsharedWithUser machine, nickname


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.stacks?.length or 0


  renderRowAtIndex: (sectionIndex, rowIndex) ->


    stack = @props.stacks[rowIndex]

    stack.machines
      .sort (a, b) -> a.label.localeCompare b.label
      .map (machine) =>
        <MachineItemContainer
          key={machine.getId()}
          stackId={stack.getId()}
          machineId={machine.getId()}
          shouldRenderDetails={yes}
          shouldRenderSpecs={yes}
          shouldRenderPower={yes}
          shouldRenderAlwaysOn={not stack.disabled}
          shouldRenderSharing={not stack.disabled}
          shouldRenderEditName={not stack.disabled}
          onChangeAlwaysOn={@lazyBound 'onChangeAlwaysOn', machine}
          onChangePowerStatus={@lazyBound 'onChangePowerStatus', machine}
          onSharedWithUser={@lazyBound 'onSharedWithUser', machine}
          onUnsharedWithUser={@lazyBound 'onUnsharedWithUser', machine}
          onChangeSharingStatus={@lazyBound 'onChangeSharingStatus', machine}
        />


  renderEmptySectionAtIndex: -> <div>No virtual machines.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewVMSection'
      rowClassName='stack'
    />
