React = require 'kd-react'
ReactView = require 'app/react/reactview'
SoloMachines = require './components/solomachines'

module.exports = class SoloMachinesListView extends ReactView

  onMachinesConfirm: (machines) ->

    @emit 'MachinesConfirmed', machines


  onHelpRequest: ->

    @emit 'SupportRequested'


  renderReact: ->

    <SoloMachines
      onMachinesConfirm={@bound 'onMachinesConfirm'}
      onHelpRequest={@bound 'onHelpRequest'}
    />
