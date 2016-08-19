kd = require 'kd'
React = require 'react'
ChargeInfo = require 'lab/ChargeInfo'

module.exports = class TrialExpireWarning extends React.Component

  @propTypes =
    expired: React.PropTypes.bool
    teamSize: React.PropTypes.string
    className: React.PropTypes.string
    pricePerSeat: React.PropTypes.string
    onClickInfo: React.PropTypes.func

  @defaultProps =
    expired: no
    teamSize: '4'
    className: ''
    pricePerSeat: '100.00'
    onClickInfo: kd.noop

  render: ->

    className = kd.utils.curry 'TrialExpireWarning', @props.className

    <div className={className}>
      <div className='TrialExpireWarning--title'>
      </div>
      <div className='TrialExpireWarning--content'>
      </div>
      <ChargeInfo
        teamSize={@props.teamSize}
        moneyPerUser={@props.moneyPerUser}
        onClick={@props.onClickInfo} />
    </div>


