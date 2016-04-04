kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
List            = require 'app/components/list'
MachineItem     = require './machineslist/listitem'


module.exports = class SharedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      machines: EnvironmentFlux.getters.sharedMachines
    }


  render: ->

    <List
      stacks={stacks}
      shouldRenderDetails={no} />


  numberOfSections: -> 1


  numberOfRowsInSection: -> @state.machines.size


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = immutable.Map {
      title: 'Shared Machine'
      machines: @state.machines or immutable.Map({})
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


SharedMachinesListContainer.include [KDReactorMixin]


