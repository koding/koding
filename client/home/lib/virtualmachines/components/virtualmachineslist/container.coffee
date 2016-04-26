kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class VirtualMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.stacks
    }


  onToggleAlwaysOn: (machine) -> EnvironmentFlux.actions.toggleMachineAlwaysOn machine


  onTogglePowerStatus: (machineId) -> EnvironmentFlux.actions.toggleMachineState machineId


  render: ->
    <View stacks={@state.stacks}
      onToggleAlwaysOn={@bound 'onToggleAlwaysOn'}
      onTogglePowerStatus={@bound 'onTogglePowerStatus'} />


VirtualMachinesListContainer.include [KDReactorMixin]


