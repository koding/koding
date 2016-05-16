FormValuesStore = require './stores/HomeTeamBillingFormValuesStore'
PaymentFlux = require 'app/flux/payment'
toImmutable = require 'app/util/toImmutable'

plainValues = [FormValuesStore.getterPath]

values = [
  plainValues
  PaymentFlux.getters.paymentValues
  (formValues, paymentValues) ->

    if isEdited(formValues)
      return formValues

    card = paymentValues.get 'groupCreditCard'

    return formValues  unless card

    formValues.withMutations (formValues) ->
      formValues
        .set 'number', formatCardNumber card.get('last4'), card.get('brand')
        .set 'expirationMonth', String card.get 'month'
        .set 'expirationYear', String card.get 'year'
        .set 'fullName', card.get 'name'
        .set 'email', card.get 'email'
        .set 'cvc', formatCvc card.get('brand')
        .set 'cardType', card.get('brand')
]

isEmpty = (formValues) ->
  formValues.reduce (acc, value) ->
    acc and not value
  , yes

isEdited = (formValues) -> formValues.get 'isEdited'


formatCardNumber = (last4, brand) ->

  return ''  unless last4

  switch brand
    when 'American Express' then "***********#{last4}"
    else "************#{last4}"


formatCvc = (brand) ->

  switch brand
    when 'American Express' then '****'
    else '***'


module.exports = {
  values
  plainValues
}


