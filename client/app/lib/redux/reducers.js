import { combineReducers } from 'redux'
import group from './modules/group'

const identity = (store) => store
export const make = (reducers = {}) => (
  combineReducers({
    group,
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
