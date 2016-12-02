kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

GitHub = require './components/github/'

module.exports = class HomeIntegrationsGitHub extends ReactView

  renderReact: ->
    <GitHub.Container />
