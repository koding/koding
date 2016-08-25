React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = GroupSuspendedMemberModal = ({ isOpen, onButtonClick }) ->

  message = "
    We were unable to charge your credit card on file. Please notify your
    admins to enter a new credit card to continue using Koding.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle="Your account is suspended."
    message={message}
    buttonTitle='NOTIFY MY ADMINS'
    onButtonClick={onButtonClick}
  />


