React = require 'kd-react'
AppearIn = require 'appearin-sdk'
View = require './view'

module.exports = class AppearInContainer extends React.Component

  constructor: (props) ->

    super props

    @appearin = new AppearIn


  render: ->
    return 'not supported'  unless @appearin.isWebRtcCompatible()

    <View appearin={@appearin} name={@props.name} />
