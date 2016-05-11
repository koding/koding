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
        .set 'number', formatCardNumber card.get 'last4'
        .set 'expirationMonth', card.get 'month'
        .set 'expirationYear', card.get 'year'
        .set 'fullName', card.get 'name'
        .set 'email', card.get 'email'
]




isEmpty = (formValues) ->
  formValues.reduce (acc, value) ->
    acc and not value
  , yes

isEdited = (formValues) -> formValues.get 'isEdited'


formatCardNumber = (last4) ->
  if last4 then "************#{last4}" else ''

module.exports = {
  values
  plainValues
}


