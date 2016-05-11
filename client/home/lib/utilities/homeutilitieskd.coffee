kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

KDCli = require './components/kdcli'

module.exports = class HomeUtilitiesKD extends ReactView

  renderReact: ->
    <KDCli.Container />
