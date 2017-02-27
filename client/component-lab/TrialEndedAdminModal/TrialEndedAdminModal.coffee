React = require 'react'
Dialog = require 'lab/Dialog'
TrialEndedOptions = require 'lab/TrialEndedOptions'

module.exports = TrialEndedAdminModal = ({ isOpen, onButtonClick, switchGroups, owner }) ->

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
    secondaryContent={TrialEndedOptions { groups: switchGroups, owner} }
  />
