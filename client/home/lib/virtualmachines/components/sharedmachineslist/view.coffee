kd              = require 'kd'
React           = require 'app/react'
immutable       = require 'immutable'
List            = require 'app/components/list'
MachineItem     = require '../machineslist/listitem'


module.exports = class SharedMachinesListView extends React.Component

  # render: ->

  #   <List
  #     stacks={stacks}
  #     shouldRenderDetails={no} />


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.machines.size


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = immutable.Map {
      title: 'Shared Machine'
      machines: @props.machines or immutable.Map({})
    }

    stack.get 'machines'
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) ->
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
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
