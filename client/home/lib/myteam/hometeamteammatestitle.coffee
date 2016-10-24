kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

TeamMates = require './components/hometeamteammates'

module.exports = class HomeTeamTeammatesTitle extends ReactView

  renderReact: ->
    <TeamMates.Title />
