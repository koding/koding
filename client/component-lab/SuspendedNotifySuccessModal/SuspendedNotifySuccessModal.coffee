React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = SuspendedNotifySuccess = ({ isOpen, onButtonClick, daysLeft }) ->

  message = "
    We have sent an email to your team admins about your subscription
    expiration. When they enter a valid credit card, you will regain access to
    Koding. We will send you an email when it is complete.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='success'
    title='Email Sent to Admins'
    subtitle='Now you should wait until they take an action'
    message={message}
    buttonType='link'
    buttonTitle='Have another issue? Contact us.'
    onButtonClick={onButtonClick}
  />
