React = require 'react'
Dialog = require 'lab/Dialog'


module.exports = TrialEndedMemberModal = (props) ->

  { isOpen, onButtonClick, secondaryContent } = props

  message = "
    We hope you have enjoyed using Koding. Please ask one of your team
    administrators to enter a credit card to continue using Koding.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle="Your team's free trial has ended."
    height='height_auto'
    message={message}
    buttonTitle='NOTIFY MY ADMINS'
    onButtonClick={onButtonClick}
    secondaryContent={secondaryContent}
  />
