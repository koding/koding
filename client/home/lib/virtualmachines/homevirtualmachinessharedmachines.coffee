kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
SharedMachinesList = require './components/sharedmachineslist'


module.exports = class HomeVirtualMachinesSharedMachines extends ReactView

  renderReact: ->
    <SharedMachinesList.Container />
