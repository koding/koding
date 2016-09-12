{ isDirty } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'

{ CREATE_TOKEN } = stripe = require 'app/redux/modules/stripe'

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
  (lastAction) ->
    switch lastAction
      when CREATE_TOKEN.FAIL, CREATE_TOKEN.SUCCESS then formMessages[lastAction]
      else null
)

submitting = (formName) -> (state) -> state.form[formName]?.submitting

mapStateToProps = (state) ->
  return {
    hasCard: state.creditCard
    submitting: submitting('create-credit-card')(state)
    isDirty: isDirty('create-credit-card')(state)
    message: formMessage state
  }

mapDispatchToProps = (dispatch) ->
  return {
    onMessageClose: -> dispatch(stripe.resetLastAction())
  }

module.exports = connect(
  mapStateToProps
  mapDispatchToProps
)(PaymentSection)

