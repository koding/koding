kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

TeamSetting = require './components/hometeamsettings'

module.exports = class HomeTeamSettings extends ReactView

  renderReact: ->
    <TeamSetting.Container />
