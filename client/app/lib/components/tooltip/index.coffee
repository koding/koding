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

    TooltipWrapperDOMNode                  = @refs.TooltipWrapper.getDOMNode()
    TooltipWrapperDOMNode.style.top        = "#{@props.tooltipY}px"
    TooltipWrapperDOMNode.style.left       = "#{@props.tooltipX}px"
    TooltipWrapperDOMNode.style.marginLeft = "#{-TooltipWrapperDOMNode.offsetWidth / 2}px"


  render: ->

    <div className={kd.utils.curry 'Tooltip-wrapper', @props.position} ref='TooltipWrapper'>
      <span>{ @props.text }</span>
    </div>

