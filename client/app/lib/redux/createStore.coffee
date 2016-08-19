{ applyMiddleware, compose, createStore } = require 'redux'
{ make: makeReducer, inject: injectReducer } = require './reducers'

module.exports = (initialState = {}) ->

  remote = require('app/remote').getInstance()
  kd = require 'kd'

  middlewares = [
    require('./middleware/bongo')(remote)
    require('./middleware/payment')(kd.singletons.paymentController)
    require('./middleware/stripe')
    require('./middleware/promise')
  ]

  return createStore(
    makeReducer()
    initialState
    applyMiddleware(middlewares...)
  )

