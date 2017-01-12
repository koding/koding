React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = SurveyAnsweredModal = ({ isOpen, onButtonClick }) ->

  message = "
    Your free credit will be deducted from your monthly subscription fee when
    your free subscription has expired.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='success'
    title='Thank you!'
    subtitle='$100 free credit has been added to your account.'
    message={message}
    buttonTitle='CLOSE'
    onButtonClick={onButtonClick}
  />
