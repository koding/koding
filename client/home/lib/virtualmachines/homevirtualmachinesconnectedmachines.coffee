kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
ConnectedMachinesList = require './components/connectedmachineslist'


module.exports = class HomeVirtualMachinesConnectedMachines extends ReactView

  renderReact: ->
    <ConnectedMachinesList.Container />
