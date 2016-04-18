kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamSetting = require './components/hometeamsettings'

module.exports = class HomeTeamSettings extends ReactView

  renderReact: ->
    <TeamSetting.Container />
