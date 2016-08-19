kd = require 'kd'
React = require 'react'

module.exports = class VerifyEmailWarning extends React.Component

  @propTypes =
    email: React.PropTypes.string
    className: React.PropTypes.string
    onClick: React.PropTypes.func

  @defaultProps =
    email: 'admin@koding.com'
    className: ''
    onClick: kd.noop

  render: ->

    className = kd.utils.curry 'VerifyEmailWarning', @props.className

    <div className={className}>
      <label className='VerifyEmailWarning--label'>
        Please verify your email address.
      </label>
      <div className='VerifyEmailWarning--content'>
        We have sent an email to {@props.email} ..........
        <a className='VerifyEmailWarning--resend' onClick={@props.onClick}>
          click to resend
        </a>
      </div>
    </div>
