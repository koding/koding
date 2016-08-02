import { combineReducers } from 'redux'

const identity = (store) => store
export const make = (reducers = {}) => (
  combineReducers({
    // entery tour reducers here
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

