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


  onSharedWithUser: (machine, nickname) ->

    debug 'shared with user', { machine, nickname }

    machine.shareUser nickname


  onUnsharedWithUser: (machine, nickname) ->

    debug 'unshared with user', { machine, nickname }

    machine.unshareUser nickname


  onDisconnectVM: (machine) ->

    debug 'machine needs to disconnect', { machine }

    kd.singletons.computeController.destroy machine


  render: ->

    stack = @props.stacks.find (stack) -> stack.isManaged()

    <View
      stack={stack}
      onDisconnectVM={@bound 'onDisconnectVM'}
      onDetailOpen={@bound 'onDetailOpen'}
      onSharedWithUser={@bound 'onSharedWithUser'}
      onUnsharedWithUser={@bound 'onUnsharedWithUser'}
    />
