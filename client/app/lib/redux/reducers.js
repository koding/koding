import { combineReducers } from 'redux'

export const make = (reducers = {}) => (
  combineReducers({
    // enter your reducers here
    identity: (f = {}) => f,
    ...reducers
  })
)

export const inject = (store, { key, reducer }) => {

  if (!store.reducers) {
    store.reducers = {}
  }

  store.reducers[key] = reducer
  store.replaceReducer(make(store.reducers))
}
