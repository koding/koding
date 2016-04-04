kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
List            = require 'app/components/list'
MachineItem     = require './machineslist/listitem'


module.exports = class ConnectedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.stacks
    }


  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @state.stacks
      .toList()
      .filter (stack) -> stack.get('title').toLowerCase() is 'managed vms'
      .size


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = @state.stacks.toList().get rowIndex

    stack.get 'machines'
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) ->
        <MachineItem
          key={machine.get '_id'} stack={stack} machine={machine}
          shouldRenderDetails={no} />


  renderEmptySectionAtIndex: -> <div>No connected machines.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />


ConnectedMachinesListContainer.include [KDReactorMixin]


