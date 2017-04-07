debug = require('debug')('dashboard:managedvmslist')
kd = require 'kd'
React = require 'app/react'
View = require './view'

connectCompute = require 'app/providers/connectcompute'

computeConnector = connectCompute({
  storage: ['stacks']
})

module.exports = computeConnector class ConnectedMachinesListContainer extends React.Component

  onDetailOpen: (machine) ->

    debug 'detail is opened', { machine }

    machine.reviveUsers { permanentOnly: yes }

    # EnvironmentFlux.actions.loadMachineSharedUsers machineId


  onSharedWithUser: (machine, nickname) ->

    debug 'shared with user', { machine, nickname }

    machine.shareUser nickname

    # EnvironmentFlux.actions.shareMachineWithUser machineId, nickname


  onUnsharedWithUser: (machine, nickname) ->

    debug 'unshared with user', { machine, nickname }

    machine.unshareUser nickname

    # EnvironmentFlux.actions.unshareMachineWithUser machineId, nickname


  onDisconnectVM: (machine) ->

    debug 'machine needs to disconnect', { machine }

    kd.singletons.computeController.destroy machine

    # EnvironmentFlux.actions.disconnectMachine machine


  render: ->

    stack = @props.stacks.find (stack) -> stack.isManaged()

    <View
      stack={stack}
      onDisconnectVM={@bound 'onDisconnectVM'}
      onDetailOpen={@bound 'onDetailOpen'}
      onSharedWithUser={@bound 'onSharedWithUser'}
      onUnsharedWithUser={@bound 'onUnsharedWithUser'}
    />
