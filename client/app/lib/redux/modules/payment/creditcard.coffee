_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'payment', 'creditcard'

REMOVE = expandActionType withNamespace 'REMOVE'

customer = require './customer'

reducer = (state = null, action) ->

  switch action.type

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, customer.schema
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


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer

  values

  remove
  REMOVE
}

