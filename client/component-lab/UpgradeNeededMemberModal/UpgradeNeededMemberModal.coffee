React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = UpgradeNeededMemberModal = (props) ->

  { isOpen, onButtonClick, onSecondaryButtonClick } = props

  message = "
    Thank you for being a loyal Koding user. We recently activated a new
    payment system. Please ask one of your admins to login to upgrade your
    team.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle="Your team needs to be upgraded."
    message={message}
    buttonTitle='NOTIFY MY ADMINS'
    onButtonClick={onButtonClick}
    secondaryButtonType='link'
    secondaryButtonTitle='Logout'
    onSecondaryButtonClick={onSecondaryButtonClick}
  />


