kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
MachineItem     = require '../machineslist/listitem'


module.exports = class VirtualMachinesListView extends React.Component

  @propTypes =
    onToggleAlwaysOn    : React.PropTypes.func
    onTogglePowerStatus : React.PropTypes.func

  @defaultProps =
    onToggleAlwaysOn    : kd.noop
    onTogglePowerStatus : kd.noop


  onToggleAlwaysOn: (machine) -> @props.onToggleAlwaysOn machine


  onTogglePowerStatus: (machine) -> @props.onTogglePowerStatus machine.get '_id'


  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.stacks
      .toList()
      .filter (stack) -> stack.get('title').toLowerCase() isnt 'managed vms'
      .size


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = @props.stacks.toList().get rowIndex

    stack.get 'machines'
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) =>
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
          shouldRenderDetails={yes}
          shouldRenderSpecs={yes}
          shouldRenderPower={yes}
          shouldRenderAlwaysOn={yes}
          shouldRenderSharing={yes}
          onToggleAlwaysOn={@lazyBound 'onToggleAlwaysOn', machine}
          onTogglePowerStatus={@lazyBound 'onTogglePowerStatus', machine} />


  renderEmptySectionAtIndex: -> <div>No virtual machines.</div>


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

