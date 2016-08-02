import thunk from 'redux-thunk'
import { applyMiddleware, compose, createStore } from 'redux'
import { make as makeReducer, inject as injectReducer } from './reducers'

export default (initialState = {}) => {
  const middlewares = [thunk]

  const store = createStore(
    makeReducer(),
    initialState,
    applyMiddleware(...middlewares)
  )

  return store
}
