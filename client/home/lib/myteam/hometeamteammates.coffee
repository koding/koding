kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamMates = require './components/hometeamteammates'

module.exports = class HomeTeamTeammates extends ReactView

  constructor: (options = {}, data) ->

    super options, data

    @state =
      role : data

  renderReact: ->
    <TeamMates.Container role={@state.role} />
