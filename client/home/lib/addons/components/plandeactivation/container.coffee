React = require 'app/react'
View = require './view'

module.exports = class PlanDeactivationContainer extends React.Component


  handleDeactivation: ->

    @props.onDeactivation()

  render: ->

    <View onDeactivation={@bound 'handleDeactivation'} target={@props.target} />
