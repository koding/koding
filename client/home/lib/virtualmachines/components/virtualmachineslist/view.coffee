kd              = require 'kd'
React           = require 'app/react'
List            = require 'app/components/list'
MachineItem     = require '../machineslist/listitem'


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


  getStacks: ->

    @props.stacks.filter (stack) -> stack.get('title').toLowerCase() isnt 'managed vms'


  onChangeAlwaysOn: (machine, state) ->

    @props.onChangeAlwaysOn machine.get('_id'), state


  onChangePowerStatus: (machine, shouldStart) ->

    @props.onChangePowerStatus machine.get('_id'), shouldStart


  onChangeSharingStatus: (machine, shouldShare) ->

    return  if shouldShare

    @props.onCancelSharing machine.get('_id')


  onSharedWithUser: (machine, nickname) ->

    @props.onSharedWithUser machine.get('_id'), nickname


  onUnsharedWithUser: (machine, nickname) ->

    @props.onUnsharedWithUser machine.get('_id'), nickname


  numberOfSections: -> 1


  numberOfRowsInSection: -> @getStacks().size



  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = @getStacks().toList().get rowIndex

    stack.get 'machines'
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) =>
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
          shouldRenderDetails={yes}
          shouldRenderSpecs={yes}
          shouldRenderPower={yes}
          shouldRenderAlwaysOn={not stack.get 'disabled'}
          shouldRenderSharing={not stack.get 'disabled'}
          shouldRenderEditName={not stack.get 'disabled'}
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
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewVMSection'
      rowClassName='stack'
    />
