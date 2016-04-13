kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

HomeTeamSetting = require './hometeamsettingscomponent'

module.exports = class HomeTeamSettings extends ReactView

  renderReact: ->
    <HomeTeamSetting.Container />
