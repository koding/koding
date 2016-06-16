kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
WelcomeSteps = require './components/welcomesteps'

module.exports = class HomeWelcomeSteps extends ReactView

  renderReact: ->
    <WelcomeSteps.Container />



