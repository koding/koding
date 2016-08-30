immutable = require 'app/util/immutable'
customer = require './customer'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

schema = defineSchema 'subscription',
  plan: defineSchema 'plan'

withNamespace = makeNamespace 'koding', 'payment', 'subscription'

LOAD = expandActionType withNamespace 'LOAD'
CREATE = expandActionType withNamespace 'CREATE'
REMOVE = expandActionType withNamespace 'REMOVE'

reducer = (state = null, action) ->

  switch action.type

    when LOAD.SUCCESS, CREATE.SUCCESS
      normalized = normalize action.result, schema
      return normalized.first 'subscription'

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, customer.schema
      return immutable normalized.first 'subscriptions'

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


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer
  load, create, remove
  LOAD, CREATE, REMOVE
}


