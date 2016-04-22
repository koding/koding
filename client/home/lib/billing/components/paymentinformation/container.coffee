kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'

CardFormValues = require '../../flux/cardformvalues'
PaymentFlux = require 'app/flux/payment'

PaymentInformation = require './view'

module.exports = class PaymentInformationContainer extends React.Component

  getDataBindings: ->
    return {
      formValues: CardFormValues.getters.values
    }


  constructor: (props) ->

    super props

    @state = { formValues: null }


  onRemoveCard: ->

    console.log 'onRemoveCard'


  onPaymentHistory: ->

    console.log 'onPaymentHistory'


  onSave: ->

    { formValues } = @state
    { reactor } = kd.singletons
    { createStripeToken, subscribeGroupPlan, loadGroupCreditCard } = PaymentFlux(reactor).actions
    { resetValues } = CardFormValues.actions

    options =
      cardNumber: formValues.get 'number'
      cardCVC: formValues.get 'cvc'
      cardMonth: formValues.get 'expirationMonth'
      cardYear: formValues.get 'expirationYear'
      cardName: formValues.get 'fullName'

    createStripeToken(options).then ({ token }) ->
      subscribeGroupPlan({ token, email: formValues.get 'email' }).then ->
        resetValues()
        loadGroupCreditCard()



  render: ->

    <PaymentInformation
      onInputValueChange={CardFormValues.actions.setValue}
      onRemoveCard={@bound 'onRemoveCard'}
      onPaymentHistory={@bound 'onPaymentHistory'}
      onSave={@bound 'onSave'}
      formValues={@state.formValues} />


PaymentInformationContainer.include [KDReactorMixin]

