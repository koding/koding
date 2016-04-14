KodingFluxStore = require 'app/flux/base/store'
actionTypes     = require '../actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class PaymentValuesStore extends KodingFluxStore

  @getterPath = 'PaymentValuesStore'

  getInitialState: -> toImmutable { isStripeClientLoaded: no }

  initialize: ->

    @on actionTypes.LOAD_STRIPE_CLIENT_SUCCESS, handleStripeCLientLoad


handleStripeCLientLoad = (flags) -> flags.set 'isStripeClientLoaded', yes

