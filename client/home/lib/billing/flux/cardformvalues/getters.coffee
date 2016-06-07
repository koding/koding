FormValuesStore = require './stores/HomeTeamBillingFormValuesStore'
FormErrorsStore = require './stores/HomeTeamBillingFormErrorsStore'
PaymentFlux = require 'app/flux/payment'
toImmutable = require 'app/util/toImmutable'
LoggedInUserEmailStore = ['LoggedInUserEmailStore']
plainValues = [FormValuesStore.getterPath]

values = [
  plainValues
  PaymentFlux.getters.paymentValues
  LoggedInUserEmailStore
  (formValues, paymentValues, email) ->

    if isEdited(formValues)
      return formValues

    card = paymentValues.get 'groupCreditCard'

    unless card
      email = if email then email else ''
      return formValues.set 'email', email

    formValues.withMutations (formValues) ->
      formValues
        .set 'number', formatCardNumber card.get('last4'), card.get('brand')
        .set 'expirationMonth', String card.get 'month'
        .set 'expirationYear', String card.get 'year'
        .set 'fullName', card.get 'name'
        .set 'email', card.get 'email'
        .set 'cvc', formatCvc card.get('brand')
        .set 'cardType', card.get('brand')
        .set 'mask', formatMask card.get 'brand'
]

isEmpty = (formValues) ->
  formValues.reduce (acc, value) ->
    acc and not value
  , yes


isEdited = (formValues) -> formValues.get 'isEdited'


formatCardNumber = (last4, brand) ->

  return ''  unless last4

  switch brand
    when 'American Express' then "**** ****** *#{last4}"
    else "**** **** **** #{last4}"


formatCvc = (brand) ->

  switch brand
    when 'American Express' then '****'
    else '***'

formatMask = (brand) ->

  switch brand
    when 'American Express' then '9999 999999 99999'
    else '9999 9999 9999 9999'


errors = [FormErrorsStore.getterPath]


module.exports = {
  values
  plainValues
  errors
}


