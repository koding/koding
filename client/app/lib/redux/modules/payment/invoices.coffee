immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'payment', 'invoices'

LOAD = expandActionType withNamespace 'LOAD'

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


module.exports = {
  namespace: withNamespace()
  reducer
  load
  LOAD
}

