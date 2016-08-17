import thunk from 'redux-thunk'
import { applyMiddleware, compose, createStore } from 'redux'
import { make as makeReducer } from './reducers'
import { loadGroup } from './modules/group'

function logger({ getState }) {
  return (next) => (action) => {
    console.log('wiill dispatch ', action)
    let returnValue = next(action)
    console.log('new state', getState(), returnValue)
  }
}

export default (initialState = {}) => {
  const middlewares = [thunk, logger]

  const store = createStore(
    makeReducer(),
    initialState,
    applyMiddleware(...middlewares)
  )

  store.dispatch(loadGroup())
  store.dispatch({type:'hayda'})

  return store
}
