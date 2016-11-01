kd = require 'kd'
React = require 'app/react'
KDReactorMixin = require 'app/flux/base/reactormixin'
CreditCard = require './view'
CardFormValues = require '../../flux/cardformvalues'
PaymentFlux = require 'app/flux/payment'


module.exports = class CreditCardContainer extends React.Component

  getDataBindings: ->
    return {
      formValues: CardFormValues.getters.values
      formErrors: CardFormValues.getters.errors
      paymentValues: PaymentFlux.getters.paymentValues
    }

  constructor: (props) ->

    super props

    @state = { formValues: null }


  onInputValueChange: (type, value) -> CardFormValues.actions.setValue type, value


  render: ->
    <CreditCard
      onInputValueChange={@bound 'onInputValueChange'}
      formValues={@state.formValues}
      formErrors={@state.formErrors}
      card={@state.paymentValues.get 'groupCreditCard'} />


CreditCardContainer.include [KDReactorMixin]
