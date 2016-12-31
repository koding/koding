immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'

schemas = require './schemas'
withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'invoices'

LOAD = reduxHelper.expandActionType withNamespace 'LOAD'

initialState = immutable { invoices: {}, items: {} }

reducer = (state = initialState, action) ->

  { normalize } = reduxHelper

  switch action.type
    when LOAD.SUCCESS
      normalized = normalize action.result, schemas.invoices
      return immutable normalized.entities

  return state


exports.load = load = ->
  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    payment: (service) -> service.fetchInvoices()
  }


all = (state) -> state.invoices?.invoices


module.exports = {
  namespace: withNamespace()
  reducer

  all

  load
  LOAD
}
