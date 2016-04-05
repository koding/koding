kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
MachineItem     = require '../machineslist/listitem'


module.exports = class VirtualMachinesListView extends React.Component

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
      .map (machine) ->
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
          shouldRenderDetails={yes}
          shouldRenderSpecs={yes}
          shouldRenderPower={yes}
          shouldRenderAlwaysOn={yes}
          shouldRenderSharing={yes} />


  renderEmptySectionAtIndex: -> <div>No virtual machines.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />

