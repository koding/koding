{ isDirty, reset: resetForm } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'

{ CREATE_TOKEN } = stripe = require 'app/redux/modules/stripe'
creditCard = require 'app/redux/modules/payment/creditcard'

PaymentSection = require './paymentsection'

formMessages = {}
formMessages[CREATE_TOKEN.SUCCESS] =
  type: 'success'
  title: 'Success!'
  description: 'We have added your credit card to your account.'

formMessages[CREATE_TOKEN.FAIL] =
  type: 'danger'
  title: 'Credit Card Error'
  description: '
    We were unable to verify your card. Please check the details you entered
    below and try again.
  '

formMessage = createSelector(
  stripe.lastAction
  (lastAction) -> lastAction and formMessages[lastAction]
)

submitting = (formName) -> (state) -> state.form[formName]?.submitting

hasSuccessModal = createSelector(
  stripe.lastAction
  (lastAction) -> lastAction is CREATE_TOKEN.SUCCESS
)

mapStateToProps = (state) ->
  return {
    hasCard: !!state.creditCard
    submitting: submitting('create-credit-card')(state)
    isDirty: isDirty('create-credit-card')(state)
    message: formMessage state
    operation: if state.creditCard then 'update' else 'create'
  }

mapDispatchToProps = (dispatch) ->
  return {
    onMessageClose: ->
      dispatch(stripe.resetLastAction())
    onResetForm: ->
      dispatch(stripe.resetLastAction())
      dispatch(resetForm('create-credit-card'))
    onRemoveCard: ->
      dispatch(stripe.resetLastAction())
      dispatch(creditCard.remove())
  }

module.exports = connect(
  mapStateToProps
  mapDispatchToProps
)(PaymentSection)

