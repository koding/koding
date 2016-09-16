React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = TrialEndedAdminModal = ({ isOpen, onButtonClick }) ->

  message = "
    We hope you have enjoyed using Koding. Please enter a credit card to
    continue using Koding.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle="Your team's free trial has ended."
    message={message}
    buttonTitle='ENTER A CREDIT CARD'
    onButtonClick={onButtonClick}
  />


