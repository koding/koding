kd = require 'kd'
reduxForm = require 'redux-form'
validator = require 'card-validator'

{ assign } = require 'lodash'
{ createSelector } = require 'reselect'

{ Brand } = require 'lab/CreditCard/constants'
{ getPlaceholder, getNumberPattern } = require 'lab/CreditCard/helpers'

FORM_NAME = 'create-credit-card'
_select = reduxForm.formValueSelector FORM_NAME

toBrand = (number) ->
  if val = validator.number(number).card?.type
  then kd.utils.slugify val
  else Brand.DEFAULT

pickDigits = (val) -> val?.replace(/\D/g, '')

$number = (state) -> if pickDigits val = _select(state, 'number') then val else ''
$brand = (state) -> if val = _select(state, 'number') then toBrand pickDigits val else ''

$exp_month = (state) -> _select(state, 'exp_month') or ''
$exp_year = (state) -> _select(state, 'exp_year') or ''
$cvc = (state) -> _select(state, 'cvc') or ''

$dirty = reduxForm.isDirty(FORM_NAME)

defaultPlaceholders =
  brand: Brand.DEFAULT
  number: ''
  exp_month: ''
  exp_year: ''
  name: getPlaceholder 'name'
  cvc: getPlaceholder 'cvc'

$placeholders = (state) ->

  return defaultPlaceholders  unless state.customer
  return defaultPlaceholders  unless card = state.creditCard

  cardBrand = kd.utils.slugify card.brand.toLowerCase()

  number = if cardBrand is Brand.AMERICAN_EXPRESS
  then "•••• •••••• •#{card.last4}"
  else "•••• •••• •••• #{card.last4}"

  return {
    brand: cardBrand
    number: number
    name: getPlaceholder 'name'
    cvc: getPlaceholder 'cvc', cardBrand
    exp_month: card.exp_month
    exp_year: card.exp_year
  }


$values = (state) ->
  return {
    brand: $brand(state)
    number: $number(state)
    exp_month: $exp_month(state)
    exp_year: $exp_year(state)
    cvc: $cvc(state)
  }


mapErrors = (errors) ->
  errors.reduce (res, { error }) ->
    res[error.param] = error.message
    return res
  , {}


module.exports = {
  FORM_NAME
  mapErrors
  select: {
    dirty: $dirty
    values: $values
    placeholders: $placeholders
  }
}
