debug = require('debug')('dashboard:listitemcontainer')
React = require 'app/react'
Machine = require 'app/remote-extensions/machine'
connectCompute = require 'app/providers/connectcompute'

MachineListItem = require './listitem'

computeConnector = connectCompute({
  storage: ['machines', 'stacks']
  defaultProps: {
    percentage: 0
    status: ''
  }
  controllerEvents: {
    stack: {
      apply: ({ status, percentage }) -> { status, percentage }
    }
    machine: {
      public: ({ status, percentage }) -> { status, percentage }
    }
  }
})

module.exports = computeConnector MachinesListItemContainer = (props) ->

  render: ->

    <MachineListItem
      machine={@props.machine}
      stack={@props.stack}
      status={@props.status}
      percentage={@props.percentage}
      shouldRenderDetails={@props.shouldRenderDetails}
      shouldRenderSpecs={@props.shouldRenderSpecs}
      shouldRenderPower={@props.shouldRenderPower}
      shouldRenderDisconnect={@props.shouldRenderDisconnect}
      shouldRenderAlwaysOn={@props.shouldRenderAlwaysOn}
      shouldRenderSharing={@props.shouldRenderSharing}
      shouldRenderEditName={@props.shouldRenderEditName}
      onChangeAlwaysOn={@props.onChangeAlwaysOn}
      onChangePowerStatus={@props.onChangePowerStatus}
      onChangeSharingStatus={@props.onChangeSharingStatus}
      onSharedWithUser={@props.onSharedWithUser}
      onUnsharedWithUser={@props.onUnsharedWithUser}
      onDisconnectVM={@props.onDisconnectVM}
    />
