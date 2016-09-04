_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'bongo'

LOAD = expandActionType withNamespace 'LOAD'
REMOVE = expandActionType withNamespace 'REMOVE'

reducer = (state = immutable({}), action) ->

  switch action.type
    when LOAD.SUCCESS
      { result } = action
      result = [result]  unless Array.isArray result
      result.forEach (res) ->
        state = state.set res.constructor.name, immutable {}  unless state[res.constructor.name]
        state = state.update res.constructor.name, (collection) ->
          collection = collection.set res._id, immutable res
          return collection

      return state

    when REMOVE.SUCCESS
      { result } = action
      result = [result]  unless Array.isArray result
      result.forEach (res) ->
        { _id, constructor: { name: constructorName } } = res
        state = state.set constructorName, state[constructorName].without(_id)

      return state

    else
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


byId = (constructorName, id) -> (state) -> state.bongo[constructorName][id]


all = (constructorName) -> (state) -> state.bongo[constructorName]


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  load, loadAll, update, remove, byId, all
  LOAD, REMOVE
}
