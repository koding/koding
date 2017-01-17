React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = VerifyEmailModal = ({ isOpen, onButtonClick, email }) ->

  message = "
    Please check your inbox and click the link in that email to verify your
    work email address. After verification, your trial will be extended to 30
    days and any free credit will be added to your account.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Please Verify Your Email Address'
    subtitle="We sent an email to #{email}"
    message={message}
    buttonTitle='CONTINUE TO KODING'
    onButtonClick={onButtonClick}
  />

VerifyEmailModal.defaultProps =
  email: 'xxxxx@xxxxxx.com'
