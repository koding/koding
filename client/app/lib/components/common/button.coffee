kd     = require 'kd'
React  = require 'kd-react'


module.exports = class Button extends React.Component

  onClick: (event) ->

    kd.utils.stopDOMEvent event
    return @props.onClick event  if @props.onClick


  render: ->
    <button
      className={kd.utils.curry 'Button', @props.className}
      onClick={@bound 'onClick'}>{@props.children}</button>




