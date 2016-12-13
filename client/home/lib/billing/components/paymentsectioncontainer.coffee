{ isDirty, reset: resetForm } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'

getGroup = require 'app/util/getGroup'
getGroupStatus = require 'app/util/getGroupStatus'

{ CREATE_TOKEN } = stripe = require 'app/redux/modules/stripe'
creditCard = require 'app/redux/modules/payment/creditcard'

{ Status } = require 'app/redux/modules/payment/constants'

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

formMessages[Status.PAST_DUE] = formMessages[Status.CANCELED] =
  type: 'danger'
  title: 'Credit Card Error'
  description: '
    Your account is suspended because we were unable to charge your card on
    file. Please enter a new card to continue using Koding.
  '

formMessage = createSelector(
  stripe.lastAction
  (lastAction) -> formMessages[lastAction or getGroupStatus(getGroup())]
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
    operation: if state.creditCard then 'change' else 'create'
    hasSuccessModal: hasSuccessModal(state)
  }

mapDispatchToProps = (dispatch) ->
  return {
    onSuccessModalClose: ->
      dispatch(stripe.resetLastAction())
      location.reload()
    onInviteMembers: ->
      dispatch(stripe.resetLastAction())
      location.replace '/Home/my-team#send-invites'
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

