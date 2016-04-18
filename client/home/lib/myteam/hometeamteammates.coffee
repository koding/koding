kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamMates = require './components/hometeamteammates'

module.exports = class HomeTeamTeammates extends ReactView

  renderReact: ->
    <TeamMates.Container />
