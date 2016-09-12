immutable = require 'app/util/immutable'
{ createSelector } = require 'reselect'
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


create = (customerId, planId) ->
  return {
    types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    payment: (service) ->
      service.createSubscription
        customer: customerId
        plan: planId
  }


remove = ->
  return {
    types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    payment: (service) -> service.deleteSubscription()
  }


##
# Selectors
##

plan = (state) -> state.subscription.plan

isTrial = (state) -> state.subscription.status is 'trialing'

endsAt = (state) -> state.subscription.current_period_end

pricePerSeat = (state) -> state.subscription.plan.amount / 100

trialDays = (state) -> plan(state).trial_period_days


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer
  load, create, remove
  LOAD, CREATE, REMOVE

  # Selectors
  plan, isTrial, endsAt, pricePerSeat
}


