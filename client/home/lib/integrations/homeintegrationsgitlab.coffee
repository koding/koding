kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

GitLab = require './components/gitlab/'

module.exports = class HomeIntegrationsGitlab extends ReactView

  renderReact: ->
    <GitLab.Container />
