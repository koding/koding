actionTypes     = require '../actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports =

  getInitialState: ->
    return toImmutable
      isStripeClientLoaded: no
      stripeToken: ''
      groupPlan: null


  initialize: ->
    @on actionTypes.LOAD_STRIPE_CLIENT_SUCCESS, handleStripeCLientLoad
    @on actionTypes.CREATE_STRIPE_TOKEN_SUCCESS, handleStripeTokenLoad
    @on actionTypes.SUBSCRIBE_GROUP_PLAN_SUCCESS, handleGroupPlanLoad
    @on actionTypes.LOAD_GROUP_CREDIT_CARD_SUCCESS, handleGroupCreditCardLoad


handleStripeCLientLoad = (values) -> values.set 'isStripeClientLoaded', yes

handleStripeTokenLoad = (values, { token }) -> values.set 'stripeToken', token

handleGroupPlanLoad = (values, { plan }) -> values.set 'groupPlan', toImmutable plan

handleGroupCreditCardLoad = (values, { card }) -> values.set 'groupCreditCard', toImmutable card


