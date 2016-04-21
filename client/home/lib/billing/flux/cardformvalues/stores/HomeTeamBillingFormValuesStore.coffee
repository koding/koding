immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'
actionTypes = require '../actiontypes'

module.exports = class HomeTeamBillingFormValuesStore extends KodingFluxStore

  getInitialState: ->
    return toImmutable
      number: ''
      expirationMonth: ''
      expirationYear: ''
      cvc: ''


  initialize: ->

    @on actions.SET_TEAM_BILLING_INPUT_VALUE, handleSetValue


handleSetValue = (values, { type, value }) -> values.set type, value
