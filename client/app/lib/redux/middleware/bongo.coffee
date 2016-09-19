_ = require 'lodash'
{ LOAD, REMOVE } = require 'app/redux/modules/bongo'

module.exports = bongoMiddleware = (remote) -> (store) -> (next) -> (action) ->

  return next action  unless action.bongo

  { bongo, type, types } = action
  rest = _.omit action, ['bongo', 'type', 'types']

  next
    types: types or generateTypes(type)
    promise: ->

      bongo(remote, { getState: store.getState }).then (results) ->

        unless Array.isArray results
          results = [results]

        results.forEach (result) ->
          result.on 'update', ->
            store.dispatch { type: LOAD.SUCCESS, result }

          result.on 'deleteInstance', ->
            store.dispatch { type: REMOVE.SUCCESS, result }

        return results


generateTypes = (type) -> [
  "#{type}_BEGIN"
  "#{type}_SUCCESS"
  "#{type}_FAIL"
]
