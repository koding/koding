kd    = require 'kd'
React = require 'app/react'

module.exports = class Link extends React.Component

  @defaultProps = href: '#'


  onClick: (event) ->

    return @props.onClick event  if @props.onClick
    return  unless @props.href

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute @props.href


  render: ->
    <a {...@props} onClick={@bound 'onClick'}>{@props.children}</a>
