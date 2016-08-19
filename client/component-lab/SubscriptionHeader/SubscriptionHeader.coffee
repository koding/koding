kd = require 'kd'
React = require 'react'

module.exports = class SubscriptionHeader extends React.Component

  @propTypes =
    className: React.PropTypes.string
    title: React.PropTypes.string
    subtitle: React.PropTypes.string
    freeCredit: React.PropTypes.string
    nextBillingAmount: React.PropTypes.string
    danger: React.PropTypes.bool

  @defaultProps =
    className: ''
    title: 'Koding Basic Trial (1 Week)'
    subtitle: 'You have 7 days left.'
    freeCredit: '100.00'
    nextBillingAmount: null
    danger: no # trial is about to expire or expired


  render: ->

    className = kd.utils.curry 'SubscriptionHeader', @props.className

    <div className={className}>
      <div>
        <div className='SubscriptionHeader--title'>{@props.title}</div>
        <div className='SubscriptionHeader--freeCredit'>Free Credit: ${@props.freeCredit}</div>
      </div>
      <div>
        <div className='SubscriptionHeader--subtitle'>{@props.subtitle}</div>
        <div className='SubscriptionHeader--billingAmount'>Next Bill Amount: ${@props.nextBillingAmount}</div>
      </div>
    </div>
