immutable = require 'app/util/immutable'

LOAD_BEGIN = 'koding/payment/invoices/LOAD_BEGIN'
LOAD_SUCCESS = 'koding/payment/invoices/LOAD_SUCCESS'
LOAD_FAIL = 'koding/payment/invoices/LOAD_FAIL'

exports = module.exports = (state = immutable({}), action) ->

  switch action.type
    when LOAD_SUCCESS
      (invoices = action.result).forEach (invoice) ->
        state = state.set invoice.id, immutable(invoice)
      return state
    else state


exports.load = load = ->
  return {
    types: [ LOAD_BEGIN, LOAD_SUCCESS, LOAD_FAIL ]
    payment: (service) -> service.loadInvoices()
  }


exports.invoices = (state) -> state.invoices

