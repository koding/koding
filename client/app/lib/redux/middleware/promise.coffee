_ = require 'lodash'

module.exports = promiseMiddleware = (store) -> (next) -> (action) ->

  if typeof action is 'function'
    return action(store.dispatch, store.getState)

  { promise, types } = action

  return next action  unless promise

  [BEGIN, SUCCESS, FAIL] = types

  action = _.omit action, ['promise', 'types']

  next _.assign {}, action, { type: BEGIN }
  return promise().then(
    (result) -> next _.assign {}, action, { result, type: SUCCESS }
    (error) -> next _.assign {}, action, { error, type: FAIL }
  ).catch (error) -> next _.assign {}, action, { error, type: FAIL }


