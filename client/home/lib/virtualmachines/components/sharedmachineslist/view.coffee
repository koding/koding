kd              = require 'kd'
React           = require 'app/react'
immutable       = require 'immutable'
List            = require 'app/components/list'
MachineItemContainer = require '../machineslist/listitemcontainer'


module.exports = class SharedMachinesListView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.machines.length


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = {
      title: 'Shared Machine'
      machines: @props.machines or []
    }

    stack.machines
      .sort (a, b) -> a.label.localeCompare(b.label) # Sorting from a to z
      .map (machine) ->
        <MachineItemContainer
          key={machine.getId()}
          stack={stack}
          machine={machine}
          shouldRenderDetails={no} />


  renderEmptySectionAtIndex: -> <div>No shared machines.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />
