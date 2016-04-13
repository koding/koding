kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

HomeTeamSendInvite = require './hometeamsendinvitescomponent'

module.exports = class HomeTeamSendInvites extends ReactView

  renderReact: ->
    <HomeTeamSendInvite.Container />