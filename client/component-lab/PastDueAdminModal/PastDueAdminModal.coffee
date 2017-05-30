React = require 'react'
Dialog = require 'lab/Dialog'


module.exports = PastDueAdminModal = (props) ->

  { isOpen, onButtonClick, secondaryContent } = props

  message = '
    We were unable to charge your credit card on file. Please enter another
    credit card to continue.
  '

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='danger'
    title='Important Message'
    subtitle='Your account is past due.'
    message={message}
    buttonTitle='REACTIVATE YOUR SUBSCRIPTION'
    onButtonClick={onButtonClick}
    secondaryButtonType='link'
    secondaryContent={secondaryContent}
  />
