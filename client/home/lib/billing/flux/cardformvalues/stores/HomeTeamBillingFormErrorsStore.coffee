immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'
actionTypes = require '../actiontypes'
paymentActionTypes = require 'app/flux/payment/actiontypes'

module.exports = class HomeTeamBillingFormErrorsStore extends KodingFluxStore

  @getterPath = 'HomeTeamBillingFormErrorsStore'


  getInitialState: -> defaultValues()


  initialize: ->

    @on paymentActionTypes.CREATE_STRIPE_TOKEN_FAIL, handleError
    @on actionTypes.RESET_TEAM_BILLING_INPUT_VALUES, defaultValues
    @on actionTypes.RESET_TEAM_BILLING_INPUT_ERRORS, defaultValues


handleError = (errors, { err }) -> errors.set err.param, yes


defaultValues = ->
  return toImmutable
    number: no
    exp_month: no
    exp_year: no
    cvc: no
    email: no


