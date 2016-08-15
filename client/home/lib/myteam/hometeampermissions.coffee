kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamPermissions = require './components/hometeampermissions'

module.exports = class HomeTeamPermissions extends ReactView

  renderReact: ->
    <TeamPermissions.Container />
