kd           = require 'kd'
React        = require 'kd-react'
dateFormat   = require 'dateformat'

module.exports = class Tooltip extends React.Component

  @propTypes =
    text : React.PropTypes.string.isRequired


  render: ->
    <div className="Tooltip-wrapper">
      <span>{ @props.text }</span>
    </div>
