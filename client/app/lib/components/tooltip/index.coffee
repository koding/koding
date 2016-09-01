kd    = require 'kd'
React = require 'kd-react'

require './styl/tooltip.styl'

module.exports = class Tooltip extends React.Component


  @defaultProps =
    tooltipY : 0
    tooltipX : 0
    position : 'top'


  renderChildren: ->

    if @props.text
      return <span>{ @props.text }</span>

    return @props.children


  render: ->

    style = {}
    style['top'] = @props.tooltipY  if @props.tooltipY
    style['left'] = @props.tooltipX  if @props.tooltipX

    <div className={kd.utils.curry 'Tooltip-wrapper', @props.position} style={style}>
      {@renderChildren()}
    </div>
