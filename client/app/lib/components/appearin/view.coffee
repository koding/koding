React = require 'kd-react'
kd = require 'kd'

module.exports = class AppearInView extends React.Component

  @propTypes =
    name: React.PropTypes.string.isRequired


  componentDidMount: ->

    {appearin, name} = @props

    appearin.addRoomToIframe @iframe, name


  render: ->
    <iframe ref={(iframe) => @iframe = iframe} />
