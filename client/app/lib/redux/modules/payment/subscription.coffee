_ = require 'lodash'
{ createSelector } = require 'reselect'

immutable = require 'app/util/immutable'
dateDiffInDays = require 'app/util/dateDiffInDays'

reduxHelper = require 'app/redux/helper'
schemas = require './schemas'

customer = require './customer'
info = require './info'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'subscription'

LOAD = reduxHelper.expandActionType withNamespace 'LOAD'
CREATE = reduxHelper.expandActionType withNamespace 'CREATE'
REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'


reducer = (state = null, action) ->

  { normalize } = reduxHelper

  switch action.type

    when LOAD.SUCCESS, CREATE.SUCCESS
      normalized = normalize action.result, schemas.subscription
      return immutable normalized.first 'subscription'

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, schemas.customer

      if subscription = normalized.first 'subscriptions'
        return immutable subscription

      return null

    when info.LOAD.SUCCESS
      normalized = normalize action.result, schemas.info
      subscription = _.assign {}, normalized.first('subscription'),
        plan: normalized.first 'expectedPlan'

      return immutable subscription

    when customer.REMOVE.SUCCESS, REMOVE.SUCCESS
      return null

    else
      return state


load = ->
  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    payment: (service) -> service.fetchSubscription()
  }


create = (customerId, planId, options = {}) ->
  return {
    types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    payment: (service) ->
      params = _.assign {}, options, { customer: customerId, plan: planId }
      service.createSubscription params
  }


remove = ->
  return {
    types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    payment: (service) -> service.deleteSubscription()
  }


##
# Selectors
##

plan = (state) -> state.subscription?.plan


isTrial = (state) -> state.subscription?.status is 'trialing'


hasNoCard = (state) -> not state.creditCard


endsAt = (state) ->
  if sub = state.subscription
  then Number(sub.current_period_end) * 1000
  else Date.now()


pricePerSeat = (state) ->
  if p = plan(state)
  then p.amount / 100
  else 0


trialDays = (state) ->

  return 0  unless state.subscription

  { trial_end, trial_start } = state.subscription

  seconds = trial_end - trial_start
  dayInSeconds = 60 * 60 * 24

  return seconds / dayInSeconds


daysLeft = createSelector(
  endsAt
  (end) -> dateDiffInDays(new Date(Number end), new Date)
)

planAmount = (state) ->
  amount = if p = plan(state) then p.amount else 0

  dollars = amount / 100

  return {
    dollars: dollars
    cents: amount
    toString: -> if dollars % 1 isnt 0 then dollars.toFixed(2) else dollars
  }


module.exports = {
  namespace: withNamespace()
  reducer
  load, create, remove
  LOAD, CREATE, REMOVE

  # Selectors
  plan, isTrial, endsAt, pricePerSeat
  trialDays, daysLeft, planAmount
}
