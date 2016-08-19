immutable = require 'app/util/immutable'

LOAD_BEGIN = 'koding/payment/creditcard/LOAD_BEGIN'
LOAD_SUCCESS = 'koding/payment/creditcard/LOAD_SUCCESS'
LOAD_FAIL = 'koding/payment/creditcard/LOAD_FAIL'

UPDATE_BEGIN = 'koding/payment/creditcard/UPDATE_BEGIN'
UPDATE_SUCCESS = 'koding/payment/creditcard/UPDATE_SUCCESS'
UPDATE_FAIL = 'koding/payment/creditcard/UPDATE_FAIL'

exports = module.exports = (state = null, action) ->

  switch action.type
    when LOAD_SUCCESS, UPDATE_SUCCESS then immutable action.result
    else state


exports.load = load = ->
  return {
    types: [ LOAD_BEGIN, LOAD_SUCCESS, LOAD_FAIL ]
    payment: (service) -> service.loadCard()
  }


exports.update = update = (token) ->
  return {
    types: [ UPDATE_BEGIN, UPDATE_SUCCESS, UPDATE_FAIL ]
    payment: (service) -> service.updateCard token
  }


exports.creditCard = (state) -> state.creditCard


