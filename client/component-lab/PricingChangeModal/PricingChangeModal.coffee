React = require 'react'

Dialog = require 'lab/Dialog'

module.exports = PricingChangeModal = (props) ->

  { isOpen, onButtonClick, onSecondaryButtonClick } = props

  style = { lineHeight: '25px' }

  message = (
    <span style={style}>
      Our pricing terms have been updated. Please visit our <PricingLink /> to
      learn more. Happy Koding!
    </span>
  )

  <Dialog
    isOpen={isOpen}
    showAlien={yes}
    type='success'
    title='Important Message'
    subtitle="Pricing terms has been updated"
    message={message}
    buttonTitle='CLOSE'
    onButtonClick={onButtonClick}
  />


PricingLink = ->
  props =
    href: "https://www.koding.com/pricing"
    target: "_blank"
    onClick: ->
      location.reload()

  <a {...props}>Pricing Page</a>
