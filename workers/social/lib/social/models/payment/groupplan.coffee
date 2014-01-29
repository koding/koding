JResourcePlan = require './resourceplan'

module.exports = class JGroupPlan extends JResourcePlan

  { calculateQuantities, subscribeToPlan } = JResourcePlan

  { secure, signature } = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      :
        subscribe :
          (signature Object, Function)

  @calculateQuantities = (calcOptions, callback) ->
    calculateQuantities.call this, calcOptions, (err, quantities) ->
      return callback err  if err

      { plan, userQuantity } = calcOptions

      unless 'custom-plan' in plan.tags
        return callback message: 'This plan is not tagged with "custom-plan"'

      queryOptions = targetOptions: selector: tags: "user"

      plan.fetchProducts null, queryOptions, (err, products) ->
        return callback err  if err
        return callback message: "no products found"  unless products?.length

        [product] = products
        { planCode } = product
        quantities[planCode] = plan.quantities[planCode] * (userQuantity or 1)

        callback null, quantities

  @getCalculationOptions = (plan, planOptions) ->
    { userQuantity } = planOptions
    {
      plan
      userQuantity
    }

  calculateCustomPlanUnitAmount = do (
    userUnitAmount     =  500 # cents
    resourceUnitAmount = 2000 # cents
  ) -> (userQuantity, resourceQuantity) ->
    (userQuantity * userUnitAmount) + 
    (resourceQuantity * resourceUnitAmount)

  @subscribeToPlan = secure (client, options, callback) ->

    { userQuantity, resourceQuantity } = options.planOptions

    if "custom-plan" in options.plan.tags
      unless userQuantity or resourceQuantity
        return callback "User and resource quantities not specified"

      options.feeAmount = calculateCustomPlanUnitAmount userQuantity, resourceQuantity

    subscribeToPlan.call this, client, options, callback
