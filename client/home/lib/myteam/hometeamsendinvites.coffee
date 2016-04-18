kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamSendInvite = require './components/hometeamsendinvites'

module.exports = class HomeTeamSendInvites extends ReactView

  renderReact: ->
    <TeamSendInvite.Container />