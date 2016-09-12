_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'payment', 'customer'

schema = defineSchema 'customer',
  sources:
    data: defineSchema ['sources']
  subscriptions:
    data: defineSchema ['subscriptions']


LOAD = expandActionType withNamespace 'LOAD'
CREATE = expandActionType withNamespace 'CREATE'
UPDATE = expandActionType withNamespace 'UPDATE'
REMOVE = expandActionType withNamespace 'REMOVE'


reducer = (state = null, action = {}) ->

  switch action.type
    when LOAD.SUCCESS, CREATE.SUCCESS, UPDATE.SUCCESS
      normalized = normalize action.result, schema
      return immutable normalized.first 'customer'
    when REMOVE.SUCCESS
      return null
    else
      return state


load = ->
  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    payment: (service) -> service.fetchCustomer()
  }


create = ->
  return {
    types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    payment: (service) -> service.createCustomer()
  }


update = (params) ->
  return {
    types: [UPDATE.BEGIN, UPDATE.SUCCESS, UPDATE.FAIL]
    payment: (service) -> service.updateCustomer(params)
  }


remove = ->
  return {
    types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    payment: (service) -> service.deleteCustomer()
  }


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer
  load, create, update, remove
  LOAD, CREATE, UPDATE, REMOVE
}

