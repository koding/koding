kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'

module.exports = class ConnectedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.stacks
    }


  onDetailOpen: (machineId) -> EnvironmentFlux.actions.loadMachineSharedUsers machineId


  onSharedWithUser: (machineId, nickname) -> EnvironmentFlux.actions.shareMachineWithUser machineId, nickname


  onUnsharedWithUser: (machineId, nickname) -> EnvironmentFlux.actions.unshareMachineWithUser machineId, nickname


  onDisconnectVM: (machine) -> EnvironmentFlux.actions.disconnectMachine machine


  render: ->

    stacks = @state.stacks?.toList().filter (s) -> s.get('title').toLowerCase() is 'managed vms'

    <View stacks={stacks}
      onDisconnectVM={@bound 'onDisconnectVM'}
      onDetailOpen={@bound 'onDetailOpen'}
      onSharedWithUser={@bound 'onSharedWithUser'}
      onUnsharedWithUser={@bound 'onUnsharedWithUser'}
    />


ConnectedMachinesListContainer.include [KDReactorMixin]
