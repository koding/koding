_ = require 'lodash'
immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'

schemas = require './schemas'

customer = require './customer'
info = require './info'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'creditcard'

REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'

reducer = (state = null, action) ->

  { normalize } = reduxHelper

  switch action.type

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, schemas.customer
      c = normalized.first 'customer'

      if c.default_source
        return normalized.entities.sources[c.default_source]

    when info.LOAD.SUCCESS
      normalized = normalize action.result, schemas.info
      c = normalized.first 'customer'

      if c.default_source
        return normalized.entities.sources[c.default_source]

    when REMOVE.SUCCESS, customer.REMOVE.SUCCESS
      return null

  return state


valueSelector = (state) -> (key, fn = _.identity) -> fn state.creditCard[key]

values = (state) ->

  return null  unless state.creditCard

  selector = valueSelector(state)

  brand = selector 'brand', (brand) -> brand.toLowerCase()
  number = selector 'last4', (last4) ->
    if brand is 'amex'
    then "•••• •••••• •#{last4}"
    else "•••• •••• •••• #{last4}"

  return immutable {
    brand: brand
    number: number
    name: selector 'name'
    exp_month: selector 'exp_month'
    exp_year: selector 'exp_year'
  }


remove = ->
  return {
    types: [ REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL ]
    payment: (service) -> service.deleteCreditCard()
  }


module.exports = {
  namespace: withNamespace()
  reducer

  values

  remove
  REMOVE
}

