actionTypes     = require '../actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports =

  getInitialState: -> toImmutable { isStripeClientLoaded: no }

  initialize: ->
    @on actionTypes.LOAD_STRIPE_CLIENT_SUCCESS, handleStripeCLientLoad
    @on actionTypes.CREATE_STRIPE_TOKEN_SUCCESS, handleStripeTokenLoad


handleStripeCLientLoad = (values) -> values.set 'isStripeClientLoaded', yes

handleStripeTokenLoad = (values, { token }) -> values.set 'stripeToken', token
