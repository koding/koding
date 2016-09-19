immutable = require 'app/util/immutable'

_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'payment', 'invoices'

LOAD = expandActionType withNamespace 'LOAD'

schema =
  data: defineSchema 'invoices', [
    lines:
      data: defineSchema 'items', []
  ]

initialState = immutable { invoices: {}, items: {} }

reducer = (state = initialState, action) ->

  switch action.type
    when LOAD.SUCCESS
      normalized = normalize action.result, schema
      return immutable normalized.entities

  return state


exports.load = load = ->
  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    payment: (service) -> service.fetchInvoices()
  }


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  load
  LOAD
}

