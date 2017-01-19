React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = TrialEndingNotifySuccessModal = ({ isOpen, onButtonClick, daysLeft }) ->

  message = "
    We have sent an email to your team admins about your team’s trial period
    expiration. We are expecting them to enter a valid credit card before the
    trial period ends.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='success'
    title='Email Sent to Admins'
    subtitle="Keep using Koding for #{daysLeft} more days in trial."
    message={message}
    buttonTitle='CLOSE'
    onButtonClick={onButtonClick}
  />

TrialEndingNotifySuccessModal.defaultProps =
  daysLeft: '{daysLeft}'
