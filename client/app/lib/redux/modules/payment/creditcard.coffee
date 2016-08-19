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

      card = normalized.entities.sources[c.default_source]
      return immutable card

    when REMOVE.SUCCESS, customer.REMOVE.SUCCESS
      return null

    else
      return state


remove = ->
  return {
    types: [ REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL ]
    payment: (service) -> service.deleteCreditCard()
  }


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  remove
  REMOVE
}

