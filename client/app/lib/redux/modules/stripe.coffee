_ = require 'lodash'
immutable = require 'app/util/immutable'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'stripe'

CREATE_TOKEN = expandActionType withNamespace 'CREATE_TOKEN'

initialState = immutable { errors: null }

reducer = (state = initialState, action = {}) ->

  switch action.type
    when CREATE_TOKEN.BEGIN, CREATE_TOKEN.SUCCESS
      return state.set 'errors', null

    when CREATE_TOKEN.FAIL
      { error } = action
      errors = if Array.isArray(error) then error else [error]
      return state.set 'errors', errors

    else
      return state


createToken = (options) ->
  return {
    types: [CREATE_TOKEN.BEGIN, CREATE_TOKEN.SUCCESS, CREATE_TOKEN.FAIL]
    stripe: (service) -> service.createToken options
  }


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  createToken
  CREATE_TOKEN
}
