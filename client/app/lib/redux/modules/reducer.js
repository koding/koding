import { combineReducers } from 'redux'
import team from './team'

export const make = (reducers = {}) => (
  combineReducers({
    team,
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
