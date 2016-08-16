import { combineReducers } from 'redux'
import teamReducer from './modules/team'

export const make = (reducers = {}) => (
  combineReducers({
    teamReducer,
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
