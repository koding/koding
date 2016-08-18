kd = require 'kd'
React = require 'react'

module.exports = class ChargeInfo extends React.Component

  @propTypes =
    teamSize: React.PropTypes.string
    pricePerSeat: React.PropTypes.string
    className: React.PropTypes.string
    info: React.PropTypes.func

  @defaultProps =
    teamSize: '4'
    pricePerSeat: '49.97'
    className: ''
    info: kd.noop


  render: ->

    className = kd.utils.curry 'ChargeInfo', @props.className

    <div className={className}>
      <label>Team size: {@props.teamSize} Developers </label>
      <label>Your monthly charge will be: {@props.pricePerSeat} per user </label>
    </div>
