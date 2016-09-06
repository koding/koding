{ assign, omit } = require 'lodash'

module.exports = promiseMiddleware = (store) -> (next) -> (action) ->

  if typeof action is 'function'
    return action(store.dispatch, store.getState)

  { promise, types } = action

  return next action  unless promise

  [BEGIN, SUCCESS, FAIL] = types

  action = omit action, ['promise', 'types']

  return new Promise (resolve, reject) ->

    begin = ->
      store.dispatch(assign {}, action, { type: BEGIN })

    success = (result) ->
      store.dispatch(assign {}, action, { result, type: SUCCESS })
      resolve(result)

    fail = (error) ->
      store.dispatch(assign {}, action, { error, type: FAIL })
      reject(error)

    begin()
    promise().then(success, fail).catch(fail)
