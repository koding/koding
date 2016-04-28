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


  onChangeAlwaysOn: (machineId, state) -> EnvironmentFlux.actions.setMachineAlwaysOn machineId, state


  onChangePowerStatus: (machineId, shouldStart) -> EnvironmentFlux.actions.setMachinePowerStatus machineId, shouldStart


  onDetailOpen: (machineId) -> EnvironmentFlux.actions.loadMachineSharedUsers machineId


  onSharedWithUser: (machineId, nickname) -> EnvironmentFlux.actions.shareMachineWithUser machineId, nickname


  render: ->
    <View stacks={@state.stacks}
      onChangeAlwaysOn={@bound 'onChangeAlwaysOn'}
      onChangePowerStatus={@bound 'onChangePowerStatus'}
      onDetailOpen={@bound 'onDetailOpen'}
      onSharedWithUser={@bound 'onSharedWithUser'}
    />


VirtualMachinesListContainer.include [KDReactorMixin]


