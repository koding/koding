kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

TeamSendInvite = require './components/hometeamsendinvites'

module.exports = class HomeTeamSendInvites extends ReactView

  constructor: (options = {}, data) ->

    super options, data

    @state =
      role : data


  renderReact: ->

    <TeamSendInvite.Container role={@state.role} />
