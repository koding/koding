React = require 'react'
Dialog = require 'lab/Dialog'


module.exports = TrialEndedAdminModal = ({ isOpen, onButtonClick, secondaryContent }) ->

  message = "
    We hope you have enjoyed using Koding. Please enter a credit card to
    continue.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle="Your team's free trial has ended."
    message={message}
    height='height_auto'
    buttonTitle='REACTIVATE YOUR SUBSCRIPTION'
    onButtonClick={onButtonClick}
    secondaryContent={secondaryContent}
  />
