kd     = require 'kd'
React  = require 'kd-react'


module.exports = class Button extends React.Component

  defaultProps=
    tabIndex: ''

  onClick: (event) ->

    kd.utils.stopDOMEvent event
    return @props.onClick event  if @props.onClick


  render: ->
    <button
      tabIndex={@props.tabIndex}
      className={kd.utils.curry 'Button', @props.className}
      onClick={@bound 'onClick'}>{@props.children}</button>




