_ = require 'lodash'
{ combineReducers } = require 'redux'

exports.make = make = (reducers = {}) ->

  customReducers = {
    stripe: require('./modules/stripe').reducer
    bongo: require('./modules/bongo').reducer
    creditCard: require('./modules/payment/creditcard').reducer
    invoices: require('./modules/payment/invoices').reducer
    subscription: require('./modules/payment/subscription').reducer
    customer: require('./modules/payment/customer').reducer
    paymentInfo: require('./modules/payment/info').reducer
    form: require('redux-form').reducer
  }

  reducers = _.assign {}, customReducers, reducers

  return combineReducers reducers


exports.inject = inject = (store, { key, reducer }) ->

  store.reducers or= {}

  store.reducers[key] = reducer
  store.replaceReducer(make store.reducers)
