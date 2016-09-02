_ = require 'lodash'
{ combineReducers } = require 'redux'

exports.make = make = (reducers = {}) ->

  customReducers =
    creditCard: require './modules/creditcard'
    invoices: require './modules/invoices'
    stripe: require './modules/stripe'
    subscription: require './modules/payment/subscription'
    customer: require './modules/payment/customer'

  reducers = _.assign {}, customReducers, reducers

  return combineReducers reducers


exports.inject = inject = (store, { key, reducer }) ->

  store.reducers or= {}

  store.reducers[key] = reducer
  store.replaceReducer(make store.reducers)


