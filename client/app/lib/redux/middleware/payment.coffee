_ = require 'lodash'

module.exports = paymentMiddleware = (service) -> (store) -> (next) -> (action) ->

  return next action  unless action.payment

  { payment, type, types } = action

  next
    types: types or generateTypes type
    promise: -> payment(service, store)


generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]
