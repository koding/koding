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
    @on actionTypes.CANCEL_EDITING_TEAM_BILLING_INPUT_VALUES, cancelEditing


handleSetValue = (values, { type, value }) ->

  values.withMutations (values) ->
    values.set 'isEdited', yes
    values.set type, value
    values.set 'cardType', extractType(values.get 'number')
    if extractType(values.get 'number') is 'American Express'
      values.set 'mask', '9999 999999 99999'
    else
      values.set 'mask', '9999 9999 9999 9999'


cancelEditing = (values) ->

  defaultValues()


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
    mask: '9999 9999 9999 9999'


extractType = (number) -> Stripe?.card.cardType(number) or 'Unknown'

