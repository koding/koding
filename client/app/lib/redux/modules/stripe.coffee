{ isEmail } = require 'validator'

immutable = require 'app/util/immutable'

CREATE_TOKEN_BEGIN = 'koding/stripe/CREATE_TOKEN_BEGIN'
CREATE_TOKEN_SUCCESS = 'koding/stripe/CREATE_TOKEN_SUCCESS'
CREATE_TOKEN_FAIL = 'koding/stripe/CREATE_TOKEN_FAIL'

initialState = immutable { token: null, errors: null }

module.exports = reducer = (state = initialState, action = {}) ->

  switch action.type
    when CREATE_TOKEN_SUCCESS
      state
        .set 'token', action.result
        .set 'errors', null
    when CREATE_TOKEN_FAIL
      { error } = action
      error = [error]  unless Array.isArray error
      state.set 'errors', immutable errors
    else state


exports.createToken = createToken = (options) ->

  types: [CREATE_TOKEN_BEGIN, CREATE_TOKEN_SUCCESS, CREATE_TOKEN_FAIL]
  stripe: (Stripe) -> new Promise (resolve, reject) ->
    return reject errors  if errors = getErrors Stripe, options
    Stripe.card.createToken options, (status, response) ->
      return reject error  if error = response.error
      resolve response.id


exports.token = (state) -> state.stripe.token


exports.errors = (state) -> state.stripe.errors


getErrors = (Stripe, options) ->

  validators =
    number: Stripe.card.validateCardNumber
    cvc: Stripe.card.validateCVC
    exp_month: (val) -> 0 < Number(val) < 13
    exp_year: (val) -> val.length in [2, 4]
    email: isEmail

  errors = []
  for key, isValid of validators when not isValid options[key]
    errors.push { param: key }

  return errors

