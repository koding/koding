_ = require 'lodash'

module.exports = bongoMiddleware = (remote) -> (store) -> (next) -> (action) ->

  return next action  unless action.bongo

  { bongo, type, types } = action
  rest = _.omit action, ['bongo', 'type', 'types']

  next
    types: types or generateTypes type
    promise: bongo(remote, { getState: store.getState })


generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]
