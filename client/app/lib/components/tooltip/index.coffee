kd           = require 'kd'
React        = require 'kd-react'
dateFormat   = require 'dateformat'

module.exports = class Tooltip extends React.Component

  @propTypes =
    text     : React.PropTypes.string.isRequired


  @defaultProps =
    tooltipY : 0
    tooltipX : 0
    position : 'top'


  componentDidMount: ->

    TooltipWrapperDOMNode = @refs.TooltipWrapper.getDOMNode()

    if @props.tooltipY
      TooltipWrapperDOMNode.style.top  = "#{@props.tooltipY}px"

    if @props.tooltipX
      TooltipWrapperDOMNode.style.left = "#{@props.tooltipX}px"


  renderChildren: ->

    if @props.text
      return <span>{ @props.text }</span>
    else if @props.children
      return @props.children

    return null


  render: ->

    <div className={kd.utils.curry 'Tooltip-wrapper', @props.position} ref='TooltipWrapper'>
      {@renderChildren()}
    </div>

