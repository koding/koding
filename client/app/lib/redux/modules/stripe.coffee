_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'stripe'

CREATE_TOKEN = expandActionType withNamespace 'CREATE_TOKEN'
RESET_LAST_ACTION = withNamespace 'RESET_LAST_ACTION'

initialState = immutable { errors: null, lastAction: null }

reducer = (state = initialState, action = {}) ->

  switch action.type
    when CREATE_TOKEN.BEGIN, CREATE_TOKEN.SUCCESS
      state = state.set 'lastAction', action.type
      return state.set 'errors', null

    when CREATE_TOKEN.FAIL
      state = state.set 'lastAction', action.type
      { error } = action
      errors = if Array.isArray(error) then error else [error]
      return state.set 'errors', errors

    when RESET_LAST_ACTION
      return state.set 'lastAction', action.type

    else
      return state


errors = (state) -> state.stripe.errors


lastAction = (state) -> state.stripe.lastAction


resetLastAction = ->
  return {
    type: RESET_LAST_ACTION
  }

createToken = (options) ->
  return {
    types: [CREATE_TOKEN.BEGIN, CREATE_TOKEN.SUCCESS, CREATE_TOKEN.FAIL]
    stripe: (service) -> service.createToken options
  }


module.exports = {
  namespace: withNamespace()
  reducer

  errors, lastAction

  createToken, resetLastAction
  CREATE_TOKEN, RESET_LAST_ACTION
}
