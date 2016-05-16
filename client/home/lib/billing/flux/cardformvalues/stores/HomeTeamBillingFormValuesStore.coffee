immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'
actionTypes = require '../actiontypes'

module.exports = class HomeTeamBillingFormValuesStore extends KodingFluxStore

  @getterPath = 'HomeTeamBillingFormValuesStore'

  getInitialState: -> defaultValues()


  initialize: ->

    @on actionTypes.SET_TEAM_BILLING_INPUT_VALUE, handleSetValue
    @on actionTypes.RESET_TEAM_BILLING_INPUT_VALUES, defaultValues


handleSetValue = (values, { type, value }) ->

  # if it's not edited before
  # let's reset all the values.
  unless values.get('isEdited')
    return defaultValues().set 'isEdited', yes

  values.withMutations (values) ->
    values.set type, value
    values.set 'cardType', extractType(values.get 'number')


defaultValues = ->
  return toImmutable
    number: ''
    expirationMonth: ''
    expirationYear: ''
    cvc: ''
    fullName: ''
    email: ''
    cardType: 'Unknown' # it's the default state from Stripe.card.cardType
    isEdited: no


extractType = (number) -> Stripe?.card.cardType(number) or 'Unknown'

