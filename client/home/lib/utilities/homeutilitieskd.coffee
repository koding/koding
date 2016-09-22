kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

KDCli = require './components/kdcli'

module.exports = class HomeUtilitiesKD extends ReactView

  renderReact: ->
    <KDCli.Container />
