appendHeadElement = require 'app/util/appendHeadElement'
{ isEmail } = require 'validator'
cardValidator = require 'card-validator'
stripeFixtures = require 'app/redux/services/fixtures/stripe'

STRIPE_API_URL = 'https://js.stripe.com/v2/'

exports.ensureClient = ensureClient = (publishableKey) -> new Promise (resolve, reject) ->

  return resolve(global.Stripe)  if global.Stripe

  # if there there is no global.Stripe or publishableKey there is something
  # wrong going on, let's reject.
  unless publishableKey
    return reject(new Error 'stripe.service: publishableKey is not set')

  appendHeadElement { type: 'script', url: STRIPE_API_URL }, (err) ->
    return reject(err)  if err
    global.Stripe.setPublishableKey publishableKey
    resolve(global.Stripe)


exports.createToken = createToken = (options) ->

  if errors = validateOptions options
    return Promise.reject(errors)

  success = (client) -> new Promise (resolve, reject) ->
    client.card.createToken options, (stat, { error, id }) ->
      if error then reject(error) else resolve(id)

  return ensureClient().then(success)


validateErrorResponses =
  number: stripeFixtures.createTokenError.number
  cvc: stripeFixtures.createTokenError.cvc
  exp_year: stripeFixtures.createTokenError.year
  exp_month: stripeFixtures.createTokenError.month
  email: stripeFixtures.createTokenError.email


validateOptions = (options) ->

  { pickBy, map } = _

  { card: { isAmex } } = cardValidator.number options.number

  validators = makeValidators isAmex

  # for each validator use the corresponding data from options
  # if return falsy there is an error for that key
  # if return truthy there is no error for that key
  # pick keys where result is falsy
  errorMap = pickBy validators, (validator, key) -> validator options[key]
  # return a list with an item of { param: key } where key is one of the keys
  # with errors.
  return map errorMap, (error, key) -> validateErrorResponses[key]


makeValidators = (isAmex) ->

  fieldValidator = (field, rest...) -> (value) ->
    cardValidator[field](value, rest...).isPotentiallyValid

  return {
    number: fieldValidator 'number'
    cvc: fieldValidator 'cvv', if isAmex then 4 else 3
    exp_month: fieldValidator 'expirationMonth'
    exp_year: fieldValidator 'expirationYear'
    email: isEmail
  }


