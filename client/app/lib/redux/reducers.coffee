_ = require 'lodash'
{ combineReducers } = require 'redux'

exports.make = make = (reducers = {}) ->

  customReducers = {
    stripe: require './modules/stripe'
    creditCard: require './modules/payment/creditcard'
    subscription: require './modules/payment/subscription'
    customer: require './modules/payment/customer'
  }

  reducers = _.assign {}, customReducers, reducers

  return combineReducers reducers


exports.inject = inject = (store, { key, reducer }) ->

  store.reducers or= {}

  store.reducers[key] = reducer
  store.replaceReducer(make store.reducers)


