kd = require 'kd'
{ isDirty, reset: resetForm } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'

getGroup = require 'app/util/getGroup'
getGroupStatus = require 'app/util/getGroupStatus'

{ CREATE_TOKEN } = stripe = require 'app/redux/modules/stripe'
creditCard = require 'app/redux/modules/payment/creditcard'
subscription = require 'app/redux/modules/payment/subscription'

{ Status } = require 'app/redux/modules/payment/constants'

PaymentSection = require './paymentsection'
{ select, FORM_NAME } = require './helpers'

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


formMessages[Status.NEEDS_UPGRADE] =
  type: 'danger'
  title: 'Your account is suspended.'
  description: '
    You have cancelled your subscription. Please enter a valid
    credit card to re-activate your subscription.
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
    submitting: submitting(FORM_NAME)(state)
    isDirty: isDirty(FORM_NAME)(state)
    message: formMessage state
    operation: if state.creditCard then 'change' else 'create'
    hasSuccessModal: hasSuccessModal(state)
    placeholders: select.placeholders(state)
  }

mapDispatchToProps = (dispatch) ->
  return {
    onSuccessModalClose: ->
      location.reload()
    onInviteMembers: ->
      location.replace '/Home/my-team#send-invites'
    onMessageClose: ->
      dispatch(stripe.resetLastAction())
    onResetForm: ->
      dispatch(stripe.resetLastAction())
      dispatch(resetForm(FORM_NAME))
    onCancelSubscription: ->
      dispatch(stripe.resetLastAction())
      dispatch(subscription.remove())
        .then -> dispatch(creditCard.remove())
        .then -> location.reload()
    onPaymentHistory: ->
      dispatch(stripe.resetLastAction())
      kd.singletons.router.handleRoute '/Home/payment-history'
  }

module.exports = connect(
  mapStateToProps
  mapDispatchToProps
)(PaymentSection)
