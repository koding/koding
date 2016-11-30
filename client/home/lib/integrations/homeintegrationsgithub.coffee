kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

Github = require './components/github/'

module.exports = class HomeIntegrationsGithub extends ReactView

  renderReact: ->
    <Github.Container />
