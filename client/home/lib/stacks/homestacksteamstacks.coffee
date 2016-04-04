kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamStackList = require './components/teamstackslist'


module.exports = class HomeStacksTeamStacks extends ReactView

  renderReact: ->
    <TeamStackList />


