import thunk from 'redux-thunk'
import { applyMiddleware, compose, createStore } from 'redux'
import { make as makeReducer, inject as injectReducer } from './reducers'

export default (initialState = {}) => {
  const middlewares = [thunk]

  console.log('creating store')
  const store = createStore(
    makeReducer(),
    initialState,
    applyMiddleware(...middlewares)
  )

  return store
}
