
LOAD_BEGIN = 'koding/payment/subscription/LOAD_BEGIN'
LOAD_SUCCESS = 'koding/payment/subscription/LOAD_SUCCESS'
LOAD_FAIL = 'koding/payment/subscription/LOAD_FAIL'

CREATE_BEGIN = 'koding/payment/subscription/CREATE_BEGIN'
CREATE_SUCCESS = 'koding/payment/subscription/CREATE_SUCCESS'
CREATE_FAIL = 'koding/payment/subscription/UPDATE_FAIL'

REMOVE_BEGIN = 'koding/payment/subscription/REMOVE_BEGIN'
REMOVE_SUCCESS = 'koding/payment/subscription/REMOVE_SUCCESS'
REMOVE_FAIL = 'koding/payment/subscription/UPDATE_FAIL'

exports = module.exports = (state = null, action) ->

  switch action.type
    when LOAD_SUCCESS, CREATE_SUCCESS then immutable action.result
    when REMOVE_SUCCESS then null
    else state


exports.load = load = ->
  return {
    types: [ LOAD_BEGIN, LOAD_SUCCESS, LOAD_FAIL ]
    payment: (service) -> service.loadSubscription()
  }


exports.create = create = (token, email) ->
  return {
    types: [ CREATE_BEGIN, CREATE_SUCCESS, CREATE_FAIL ]
    payment: (service) -> service.createSubscription(token, email)
  }


exports.remove = remove = ->
  return {
    types: [ REMOVE_BEGIN, REMOVE_SUCCESS, REMOVE_FAIL ]
    payment: (service) -> service.removeSubscription()
  }


