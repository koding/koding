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
      formErrors: CardFormValues.getters.errors
    }


  constructor: (props) ->

    super props

    @state = { formValues: null }


  onRemoveCard: ->

    { reactor } = kd.singletons
    { actions, getters } = PaymentFlux reactor

    if getters.paymentValues().get 'groupCreditCard'
      actions.removeGroupPlan().then ->
        showSuccess 'Your card has been removed successfully.'


  onPaymentHistory: ->

    kd.singletons.router.handleRoute '/Home/payment-history'


  onSave: ->

    { formValues } = @state
    { reactor } = kd.singletons
    { actions, getters } = PaymentFlux reactor

    { createStripeToken, subscribeGroupPlan
      loadGroupCreditCard, updateGroupCreditCard } = actions

    { resetValues, resetErrors } = CardFormValues.actions

    options =
      cardNumber: formValues.get 'number'
      cardCVC: formValues.get 'cvc'
      cardMonth: formValues.get 'expirationMonth'
      cardYear: formValues.get 'expirationYear'
      cardName: formValues.get 'fullName'
      cardEmail: formValues.get 'email'

    resetErrors()
    createStripeToken(options).then ({ token }) ->

      if getters.paymentValues().get 'groupCreditCard'
        updateGroupCreditCard({ token }).then ->
          resetValues()
          loadGroupCreditCard()
          showSuccess 'Your card has been updated successfully.'

      else
        subscribeGroupPlan({ token, email: formValues.get 'email' }).then ->
          resetValues()
          loadGroupCreditCard()
          showSuccess 'Your card has been saved successfully.'


  render: ->

    <PaymentInformation
      onInputValueChange={CardFormValues.actions.setValue}
      onRemoveCard={@bound 'onRemoveCard'}
      onPaymentHistory={@bound 'onPaymentHistory'}
      onSave={@bound 'onSave'}
      formErrors={@state.formErrors}
      formValues={@state.formValues} />


PaymentInformationContainer.include [KDReactorMixin]

showSuccess = (title) -> new kd.NotificationView { title }

