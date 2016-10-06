_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'bongo'

LOAD = expandActionType withNamespace 'LOAD'
REMOVE = expandActionType withNamespace 'REMOVE'

reducer = (state = immutable({}), action) ->

  switch action.type

    when LOAD.SUCCESS
      { result: results } = action
      results = [results]  unless Array.isArray results

      results.forEach (result) ->
        unless state[result.constructor.name]
          state = state.set result.constructor.name, immutable {}

        state = state.update result.constructor.name, (collection) ->
          return collection.set result._id, immutable result

    when REMOVE.SUCCESS
      { result: results } = action
      results = [results]  unless Array.isArray results

      results.forEach (result) ->
        removed = state[result.constructor.name].without(result._id)
        state = state.set result.constructor.name, removed

  return state


loadAll = (constructorName) ->
  return {
    types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
    bongo: (remote) -> remote.api[constructorName].some({})
  }


update = (instance, query) ->
  return {
    types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
    bongo: -> instance.update query, (result) -> { result: instance }
  }


remove = (instance) ->
  return {
    types: [ REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL ]
    bongo: -> instance.remove().then -> { result: instance }
  }


load = (constructorName, _id) ->
  return {
    types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
    bongo: (remote) -> remote.api[constructorName].one { _id }
  }


byId = (constructorName, id) -> (state) -> state.bongo[constructorName]?[id]


all = (constructorName) -> (state) -> state.bongo[constructorName]


module.exports = {
  namespace: withNamespace()
  reducer
  load, loadAll, update, remove, byId, all
  LOAD, REMOVE
}
