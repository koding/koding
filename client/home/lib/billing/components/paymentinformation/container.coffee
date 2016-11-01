kd = require 'kd'
React = require 'app/react'
KDReactorMixin = require 'app/flux/base/reactormixin'
whoami = require 'app/util/whoami'

CardFormValues = require '../../flux/cardformvalues'
PaymentFlux = require 'app/flux/payment'
TeamFlux = require 'app/flux/teams'
PaymentInformation = require './view'

module.exports = class PaymentInformationContainer extends React.Component

  getDataBindings: ->
    return {
      formValues: CardFormValues.getters.values
      formErrors: CardFormValues.getters.errors
      userEmail: TeamFlux.getters.loggedInUserEmail
    }


  constructor: (props) ->

    super props

    { firstName, lastName } = whoami().profile

    @state =
      formValues: null
      fullName: "#{firstName} #{lastName}"


  onRemoveCard: ->

    { reactor } = kd.singletons
    { actions, getters } = PaymentFlux reactor

    if getters.paymentValues().get 'groupCreditCard'
      actions.removeGroupPlan().then ->
        showSuccess 'Your card has been removed successfully.'


  onPaymentHistory: ->

    kd.singletons.router.handleRoute '/Home/payment-history'


  onCancel: -> CardFormValues.actions.cancelEditing()


  onSave: ->

    { formValues } = @state
    { reactor } = kd.singletons
    { actions, getters } = PaymentFlux reactor

    { createStripeToken, subscribeGroupPlan
      loadGroupCreditCard, updateGroupCreditCard } = actions

    { resetValues, resetErrors } = CardFormValues.actions

    cardName = if formValues.get 'fullName'
    then formValues.get 'fullName'
    else @state.fullName

    cardEmail = if formValues.get 'email'
    then formValues.get('email')
    else @state.userEmail

    options =
      cardNumber: formValues.get 'number'
      cardCVC: formValues.get 'cvc'
      cardMonth: formValues.get 'expirationMonth'
      cardYear: formValues.get 'expirationYear'
      cardName: cardName
      cardEmail: cardEmail

    resetErrors()
    createStripeToken(options).then ({ token }) ->

      if getters.paymentValues().get 'groupCreditCard'
        updateGroupCreditCard({ token }).then ->
          resetValues()
          loadGroupCreditCard()
          showSuccess 'Your card has been updated successfully.'

      else
        subscribeGroupPlan({ token, email: cardEmail }).then ->
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
      formValues={@state.formValues}
      userEmail={@state.userEmail}
      fullName={@state.fullName}
      onCancel={@bound 'onCancel'} />


PaymentInformationContainer.include [KDReactorMixin]

showSuccess = (title) -> new kd.NotificationView { title }

