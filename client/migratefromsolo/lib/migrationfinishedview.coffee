kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
MigrationFinished = require './components/migrationfinished'


module.exports = class MigrationFinishedView extends ReactView

  onClick: (event) ->

    kd.utils.stopDOMEvent event
    @emit 'GoToStacksRequested'


  renderReact: -> <MigrationFinished onClick={@bound 'onClick'} />



