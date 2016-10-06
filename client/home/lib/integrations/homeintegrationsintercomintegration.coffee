kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

IntercomIntegration = require './components/intercomintegration/'

module.exports = class HomeUtilitiesIntercomIntegration extends ReactView

  renderReact: ->
    <IntercomIntegration.Container />
