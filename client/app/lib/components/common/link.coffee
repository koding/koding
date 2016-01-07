kd    = require 'kd'
React = require 'kd-react'

module.exports = class Link extends React.Component

  @defaultProps = href: '#'


  onClick: (event) ->

    return @props.onClick event  if @props.onClick

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute @props.href


  render: ->
    <a {...@props} onClick={@bound 'onClick'}>{@props.children}</a>
