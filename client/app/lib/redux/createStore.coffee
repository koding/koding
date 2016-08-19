{ applyMiddleware, compose, createStore } = require 'redux'
{ make: makeReducer, inject: injectReducer } = require './reducers'

module.exports = (initialState = {}) ->

  remote = require('app/remote').getInstance()
  kd = require 'kd'

  middlewares = [
    require('./middleware/bongo')(remote)
    require('./middleware/stripe')
    require('./middleware/payment')(require './services/payment')
    require('./middleware/promise')
  ]

  return createStore(
    makeReducer()
    initialState
    applyMiddleware(middlewares...)
  )

