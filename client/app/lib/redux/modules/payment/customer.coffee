immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'

schemas = require './schemas'

info = require './info'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'customer'

LOAD = reduxHelper.expandActionType withNamespace 'LOAD'
CREATE = reduxHelper.expandActionType withNamespace 'CREATE'
UPDATE = reduxHelper.expandActionType withNamespace 'UPDATE'
REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'


reducer = (state = null, action = {}) ->

  { normalize } = reduxHelper

  switch action.type
    when info.LOAD.SUCCESS
      normalized = normalize action.result, schemas.info
      return immutable normalized.first 'customer'
    when LOAD.SUCCESS, CREATE.SUCCESS, UPDATE.SUCCESS
      normalized = normalize action.result, schemas.customer
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


module.exports = {
  namespace: withNamespace()
  reducer

  coupon, email

  load, create, update, remove
  LOAD, CREATE, UPDATE, REMOVE
}

