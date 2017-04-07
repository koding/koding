debug = require('debug')('dashboard:vmlist')
kd = require 'kd'
React = require 'app/react'
View = require './view'

connectCompute = require 'app/providers/connectcompute'

computeConnector = connectCompute({
  storage: ['stacks']
})

module.exports = computeConnector class VirtualMachinesListContainer extends React.Component

  onChangeAlwaysOn: (machine, state) ->

    debug 'change always on', { machine, state }

    kd.singletons.computeController.setAlwaysOn machine, state


  onChangePowerStatus: (machine, shouldStart) ->

    debug 'change power status', { machine, shouldStart }

    if shouldStart then machine.start() else machine.stop()


  onCancelSharing: (machine) ->

    debug 'cancel sharing', { machine }

    machine.unshareAllUsers()


  onSharedWithUser: (machine, nickname) ->

    debug 'shared with user', { machine, nickname }

    machine.shareUser nickname


  onUnsharedWithUser: (machine, nickname) ->

    debug 'unshared with user', { machine, nickname }

    machine.unshareUser nickname


  render: ->

    stacks = @props.stacks.filter (stack) -> not stack.isManaged()

    <View stacks={stacks}
      onChangeAlwaysOn={@bound 'onChangeAlwaysOn'}
      onChangePowerStatus={@bound 'onChangePowerStatus'}
      onSharedWithUser={@bound 'onSharedWithUser'}
      onUnsharedWithUser={@bound 'onUnsharedWithUser'}
      onCancelSharing={@bound 'onCancelSharing'}
    />
