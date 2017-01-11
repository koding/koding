Promise = require 'bluebird'
reduxHelper = require 'app/redux/helper'

# experimental naming convention. r$<moduleName>
r$customer = require './customer'
r$subscription = require './subscription'
r$card = require './creditcard'
r$stripe = require '../stripe'

{ Plan } = require './constants'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment'

UPDATE_CARD = reduxHelper.expandActionType withNamespace 'UPDATE_CARD'

# @param {object} obj
# @param {string} field - Field to check existence for
# @param {object} ensurer - ensurer which should return a Promise
# @return {Promise} resolves with value, if exist in state; if not resolves result of ensurer.
ensure = (obj, field, ensurer) ->
  if value = obj[field]
  then Promise.resolve(value)
  else ensurer()


# ensureCustomer: ensures payment customer by creating a new one if it doesn't
# exist.
#
# @param {store} Redux Store
# @return {Promise}
ensureCustomer = (store) ->
  ensure store.getState(), 'customer', ->
    store.dispatch r$customer.create()


# ensureSubscription: ensures payment subscription by creating a new
# subcription with Free Plan for payment customer.
#
# NOTE: this is an internal helper, and it naively assumes that there is a
# customer in the store state. It will throw if there is no customer.
#
# @private
# @param store {object} Redux Store
# @return {Promise}
ensureSubscription = (store) ->
  ensure store.getState(), 'subscription', ->
    { customer } = store.getState()
    store.dispatch r$subscription.create(customer.id, Plan.FREE)


# createToken: creates a stripe token by dispatching corresponding action.
#
# @param store {object} Redux store
# @param params {object} create token request params.
# @return {Promise}
createToken = (store, params) -> store.dispatch r$stripe.createToken params


# authorizeCard: authorizes given credit card field values.
#
# @param store {object} Redux store
# @param values {object} credit card data
# @return {Promise} resolves when authorization is successful
authorizeCard = (store, values) ->

  # FIXME(umut): after authorization endpoint supports logged in requests
  return ensureCustomer(store)

  requirements = [
    ensureCustomer(store)
    createToken(store, values)
  ]

  Promise.join requirements..., (customer, token) ->
    params = { source: { token }, email: customer.email }
    store.dispatch r$card.authorize(params)


# @param store {object} Redux store
# @param values {object} credit card data
# @return {Promise} resolves when card is successfully attached to customer.
attachCard = (store, params) ->

  requirements = [
    ensureCustomer(store)
    createToken(store, params)
  ]

  Promise.join requirements..., (customer, token) ->
    params = { source: { token, default: yes } }
    store.dispatch r$customer.update(params)


# updateCard: an action creator which will update the payment customer's credit card
# intelligently.
#
# @param values {object} credit card data
# @return {Promise} resolves when card is successfully attached to customer.
updateCard = (values) ->
  return {
    types: [ UPDATE_CARD.BEGIN, UPDATE_CARD.SUCCESS, UPDATE_CARD.FAIL ]
    payment: (service, store) ->
      Promise.resolve()
        .then -> authorizeCard(store, values)
        .then -> attachCard(store, values)
        .then -> ensureSubscription(store)
  }


module.exports = {
  updateCard
}
