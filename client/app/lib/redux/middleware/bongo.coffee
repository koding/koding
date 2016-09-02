_ = require 'lodash'

module.exports = bongoMiddleware = (remote) -> (store) -> (next) -> (action) ->
  return next action  unless action.bongo
  { bongo, type, types } = action
  rest = _.omit action, ['bongo', 'type', 'types']

  next
    types: types or generateTypes(type or 'BONGO')
    promise: ->
      bongo(remote, { getState: store.getState }).then (results) ->
        results = [results]  unless Array.isArray results
        results.forEach (result) ->
          result.on 'update', ->
            store.dispatch { type: 'BONGO_SUCCESS', result }

          result.on 'deleteInstance', ->
            store.dispatch
              type: 'BONGO_DELETE_SUCCESS'
              result: result

        return results


generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]
