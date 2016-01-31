React = require 'kd-react'
kd = require 'kd'

module.exports = class AppearInView extends React.Component

  componentDidMount: ->

    {appearin, name} = @props

    appearin.addRoomToIframe @iframe, name


  render: ->
    <iframe ref={(iframe) => @iframe = iframe} />
