{ Base } = require 'bongo'

module.exports = class JResourcePlan extends Base

  { signature, secure } = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      :
        subscribe :
          (signature Object, Function)

  @calculateQuantities = (options, callback) ->
    { plan, resourceQuantity } = options

    plan.fetchProducts (err, products) ->
      return callback err  if err
      return callback message: "no products found"  unless products?.length

      quantities = {}

      for product in products when product
        { planCode } = product

        quantities[planCode] = plan.quantities[planCode] * (resourceQuantity or 1)

      callback null, quantities

  @getCalculationOptions = (plan, planOptions) ->
    { resourceQuantity } = planOptions  if planOptions
    {
      plan
      resourceQuantity
    }

  @subscribeToPlan = (client, options, callback) ->
    { plan, planOptions, promotionType, paymentMethodId } = options

    { resourceQuantity } = planOptions  if planOptions

    calcOptions = @getCalculationOptions plan, planOptions

    @calculateQuantities calcOptions, (err, quantities) ->
      return callback err  if err

      options.quantities = quantities
      options.couponCode = plan.couponCodes?[promotionType]

      plan.subscribe$ client, paymentMethodId, options, callback

  @subscribe = secure (client, options, callback) ->
    JPaymentPlan = require './plan'

    { planCode } = options

    JPaymentPlan.one { planCode }, (err, plan) =>
      return callback err  if err

      options.plan = plan

      @subscribeToPlan client, options, callback
