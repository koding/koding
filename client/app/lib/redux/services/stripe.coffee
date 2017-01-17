appendHeadElement = require 'app/util/appendHeadElement'
cardValidator = require 'card-validator'
stripeFixtures = require 'app/redux/services/fixtures/stripe'

STRIPE_API_URL = 'https://js.stripe.com/v2/'

stripeRequestKeys = ['number', 'cvc', 'name', 'exp_month', 'exp_year']


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

  errors = validateOptions options

  if errors.length
    return Promise.reject(errors)

  # stripe returns Bad request error if we send more request parameter then it
  # accepts, make sure we are not sending more than enough.
  options = _.pick options, stripeRequestKeys

  success = (client) -> new Promise (resolve, reject) ->
    client.card.createToken options, (stat, { error, id }) ->
      if error then reject(error) else resolve(id)

  return ensureClient().then(success)


validateErrorResponses =
  number: stripeFixtures.createTokenError.number
  cvc: stripeFixtures.createTokenError.cvc
  exp_year: stripeFixtures.createTokenError.year
  exp_month: stripeFixtures.createTokenError.month


pickBy = (obj, fn) ->

  Object.keys(obj)
    .filter (key) -> fn(obj[key], key)
    .reduce (res, key) ->
      res[key] = obj[key]
      return res
    , {}


validateOptions = (options) ->

  isAmex = cardValidator.number(options.number).card?.isAmex

  validators = makeValidators isAmex

  # for each validator use the corresponding data from options
  # if return falsy there is an error for that key
  # if return truthy there is no error for that key
  # pick keys where result is falsy
  notValidMap = pickBy validators, (validator, key) -> not validator options[key]
  # return a list with an item of { param: key } where key is one of the keys
  # with errors.
  return _.map notValidMap, (error, key) -> validateErrorResponses[key]


makeValidators = (isAmex) ->

  fieldValidator = (field, rest...) -> (value) ->
    value = value.toString()
    cardValidator[field](value, rest...).isValid

  return {
    number: fieldValidator 'number'
    cvc: fieldValidator 'cvv', if isAmex then 4 else 3
    exp_month: fieldValidator 'expirationMonth'
    exp_year: fieldValidator 'expirationYear'
  }
