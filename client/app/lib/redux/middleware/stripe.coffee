_ = require 'lodash'
appendHeadElement = require 'app/util/appendHeadElement'

STRIPE_API_URL = 'https://js.stripe.com/v2/'

module.exports = stripeMiddleware = (store) -> (next) -> (action) ->

  return next action  unless action.stripe

  { stripe, type, types } = action

  success = (Stripe) ->
    types: types or generateTypes type
    promise: -> stripe(Stripe, { getState: store.getState })

  return next success global.Stripe  if global.Stripe

  appendHeadElement { type: 'script', url: STRIPE_API_URL }, (err) ->
    return console.error('Stripe client error')  if err
    next success global.Stripe

generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]

