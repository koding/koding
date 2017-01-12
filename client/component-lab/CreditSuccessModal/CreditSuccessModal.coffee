React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = CreditSuccessModal = ({ isOpen, onButtonClick }) ->

  message = "
    Your free credit can be applied to payments for your entire team
    after you have verified your email address and entered your
    credit card.
  "

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='success'
    title='Good News'
    subtitle='You have received $500 in free credit.'
    message={message}
    buttonTitle='OK, GOT IT'
    onButtonClick={onButtonClick}
  />
