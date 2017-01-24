
module.exports = stripeMiddleware = (service, publishableKey) -> (store) -> (next) -> (action) ->

  return next action  unless action.stripe

  { stripe, type, types } = action

  next
    types: types or generateTypes type
    promise: ->
      service.ensureClient(publishableKey).then ->
        stripe(service, { getState: store.getState })


generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]
