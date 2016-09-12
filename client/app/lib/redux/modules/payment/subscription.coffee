_ = require 'lodash'
immutable = require 'app/util/immutable'
{ createSelector } = require 'reselect'
dateDiffInDays = require 'app/util/dateDiffInDays'

customer = require './customer'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

schema = defineSchema 'subscription'

withNamespace = makeNamespace 'koding', 'payment', 'subscription'

LOAD = expandActionType withNamespace 'LOAD'
CREATE = expandActionType withNamespace 'CREATE'
REMOVE = expandActionType withNamespace 'REMOVE'

reducer = (state = null, action) ->

  switch action.type

    when LOAD.SUCCESS, CREATE.SUCCESS
      normalized = normalize action.result, schema
      return immutable normalized.first 'subscription'

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, customer.schema

      if subscription = normalized.first 'subscriptions'
        return immutable subscription

      return null

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

isTrialing = (state) -> state.subscription?.status is 'trialing'

hasNoCard = (state) -> not state.creditCard

isTrial = createSelector(
  isTrialing
  hasNoCard
  (trialing, noCard) -> noCard and trialing
)


endsAt = (state) ->
  if sub = state.subscription
  then Number(sub.current_period_end) * 1000
  else Date.now()

pricePerSeat = (state) ->

  if p = plan(state) then p.amount / 100 else 0

trialDays = (state) -> plan(state)?.trial_period_days

daysLeft = createSelector(
  endsAt
  (end) -> dateDiffInDays(new Date(Number end), new Date)
)


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer
  load, create, remove
  LOAD, CREATE, REMOVE

  # Selectors
  plan, isTrial, endsAt, pricePerSeat, trialDays, daysLeft
}


