globals = require 'globals'
{ applyMiddleware, compose, createStore } = require 'redux'
{ make: makeReducer, inject: injectReducer } = require './reducers'

module.exports = (initialState = {}) ->

  remote = require 'app/remote'
  { token: stripeToken } = globals.config.stripe

  middlewares = [
    require('./middleware/bongo')(remote)
    require('./middleware/payment')(require './services/payment')
    require('./middleware/stripe')(require('./services/stripe'), stripeToken)
    require('./middleware/promise')
  ]

  return createStore(
    makeReducer()
    initialState
    applyMiddleware(middlewares...)
  )
