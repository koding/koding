kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

HomeTeamTeamMates = require './hometeamteammatescomponent'

module.exports = class HomeTeamTeammates extends ReactView

  renderReact: ->
    <HomeTeamTeamMates.Container />
