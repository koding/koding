_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType, normalize } = require 'app/redux/helper'

{ customer: schema, info: infoSchema } = require './schemas'

info = require './info'

withNamespace = makeNamespace 'koding', 'payment', 'customer'

LOAD = expandActionType withNamespace 'LOAD'
CREATE = expandActionType withNamespace 'CREATE'
UPDATE = expandActionType withNamespace 'UPDATE'
REMOVE = expandActionType withNamespace 'REMOVE'


reducer = (state = null, action = {}) ->

  switch action.type
    when info.LOAD.SUCCESS
      normalized = normalize action.result, infoSchema
      return immutable normalized.first 'customer'
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


create = (options = {}) ->
  return {
    types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    payment: (service) -> service.createCustomer(options)
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


coupon = (state) -> state.customer?.discount?.coupon

email = (state) -> state.customer?.email


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer

  coupon, email

  load, create, update, remove
  LOAD, CREATE, UPDATE, REMOVE
}

