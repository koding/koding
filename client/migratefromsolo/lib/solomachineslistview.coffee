React = require 'kd-react'
ReactView = require 'app/react/reactview'
SoloMachines = require './components/solomachines'

module.exports = class SoloMachinesListView extends ReactView

  onMachinesConfirm: (machines) ->

    @emit 'MachinesConfirmed', machines


  renderReact: ->

    <SoloMachines onMachinesConfirm={@bound 'onMachinesConfirm'} />


