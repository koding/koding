kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
CreditCard = require './view'
CardFormValues = require '../../flux/cardformvalues'
PaymentFlux = require 'app/flux/payment'


module.exports = class CreditCardContainer extends React.Component

  getDataBindings: ->
    return {
      formValues: CardFormValues.getters.values
      paymentValues: PaymentFlux.getters.paymentValues
    }

  constructor: (props) ->

    super props

    @state = { formValues: null }


  render: ->
    <CreditCard
      onInputValueChange={CardFormValues.actions.setValue}
      formValues={@state.formValues}
      card={@state.paymentValues.get 'groupCreditCard'} />


CreditCardContainer.include [KDReactorMixin]
