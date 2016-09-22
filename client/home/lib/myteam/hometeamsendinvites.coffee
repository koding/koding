kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

TeamSendInvite = require './components/hometeamsendinvites'

module.exports = class HomeTeamSendInvites extends ReactView

  renderReact: ->

    <TeamSendInvite.Container />
