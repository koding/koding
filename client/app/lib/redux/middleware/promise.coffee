{ assign, omit } = require 'lodash'

module.exports = promiseMiddleware = (store) -> (next) -> (action) ->

  if typeof action is 'function'
    return action(store.dispatch, store.getState)

  { promise, types } = action

  return next action  unless promise

  [BEGIN, SUCCESS, FAIL] = types

  action = omit action, ['promise', 'types']

  begin = -> next(assign {}, action, { type: BEGIN })
  success = (result) -> next(assign {}, action, { result, type: SUCCESS })
  fail = (error) -> next(assign {}, action, { error, type: FAIL })

  begin()
  return promise().then(success, fail).catch(fail)


