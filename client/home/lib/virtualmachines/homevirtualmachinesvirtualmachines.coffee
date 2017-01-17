kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
VirtualMachinesList = require './components/virtualmachineslist'


module.exports = class HomeVirtualMachinesVirtualMachines extends ReactView

  renderReact: ->
    <VirtualMachinesList.Container />
