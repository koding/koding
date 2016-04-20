appendHeadElement = require 'app/util/appendHeadElement'
constants = require './constants'
actionTypes = require './actiontypes'
globals = require 'globals'
getters = require './getters'

loadStripeClient = ({ dispatch, evaluate }) -> ->

  new Promise (resolve, reject) ->

    flags = evaluate getters.paymentValues

    return resolve()  if flags.get 'isStripeClientLoaded'

    dispatch actionTypes.LOAD_STRIPE_CLIENT_BEGIN

    appendHeadElement { type: 'script', url: constants.STRIPE_API_URL }, (err) ->
      if err
        dispatch actionTypes.LOAD_STRIPE_CLIENT_FAIL, { err }
        reject err
        return

      Stripe.setPublishableKey globals.config.stripe.token

      dispatch actionTypes.LOAD_STRIPE_CLIENT_SUCCESS
      resolve()


createStripeToken = ({ dispatch, evaluate }) -> (options) ->

  tokenOptions =
    number    : options.cardNumber
    cvc       : options.cardCVC
    exp_month : options.cardMonth
    exp_year  : options.cardYear
    name      : options.cardName

  new Promise (resolve, reject) ->
    loadStripeClient({ dispatch, evaluate })().then ->
      Stripe.card.createToken tokenOptions, (status, response) ->
        if err = response.error
          dispatch actionTypes.CREATE_STRIPE_TOKEN_FAIL, { err }
          reject err
          return

        token = response.id

        dispatch actionTypes.CREATE_STRIPE_TOKEN_SUCCESS, { token }
        resolve { token }


subscribeGroupPlan = ({ dispatch, evaluate }) -> ({ token }) ->

  { paymentController } = kd.singletons

  return new Promise (resolve, reject) ->
    dispatch actionTypes.SUBSCRIBE_GROUP_PLAN_BEGIN

    paymentController.subscribeGroup token, (err, plan) ->
      if err
        dispatch actionTypes.SUBSCRIBE_GROUP_PLAN_FAIL, { err }
        reject err
        return

      dispatch actionTypes.SUBSCRIBE_GROUP_PLAN_SUCCESS, { plan }
      resolve { plan }


module.exports = {
  loadStripeClient
  createStripeToken
}
