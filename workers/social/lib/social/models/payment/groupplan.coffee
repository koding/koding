JResourcePlan = require './resourceplan'
JPaymentPack  = require './pack'
JPaymentFulfillmentNonce = require './nonce'

module.exports = class JGroupPlan extends JResourcePlan

  { calculateQuantities, subscribeToPlan } = JResourcePlan

  { dash, secure, signature } = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      :
        subscribe :
          (signature Object, Function)
        hasGroupCredit:
          (signature Function)

  @hasGroupCredit = secure (client, callback) ->
    { delegate } = client.connection

    JGroup = require '../group'

    JGroup.one slug: 'koding', (err, koding) ->
      return callback err  if err

      packOptions = targetOptions: selector: tags: 'group'

      koding.fetchPack {}, packOptions, (err, pack) ->
        return callback err  if err

        subOptions = targetOptions: selector: tags: 'custom-plan'

        delegate.fetchSubscription {}, subOptions, (err, subscription) ->
          return callback err  if err
          return callback null, no  unless subscription

          subscription.checkUsage pack, (err) ->
            callback err, !err?

  @calculateQuantities = (calcOptions, callback) ->
    calculateQuantities.call this, calcOptions, (err, quantities) =>
      return callback err  if err

      { plan, userQuantity } = calcOptions

      unless 'custom-plan' in plan.tags
        return callback message: 'This plan is not tagged with "custom-plan"'

      queue = [
        =>
          @fetchProductCode plan, "user", (err, productCode) ->
            return callback err  if err

            quantities[productCode] =
              plan.quantities[productCode] * (userQuantity or 1)

            queue.fin()
        =>
          @fetchProductCode plan, "group", (err, productCode) ->
            return callback err  if err

            quantities[productCode] = plan.quantities[productCode]

            queue.fin()
      ]
      dash queue, -> callback null, quantities

  @fetchProductCode = (plan, tags, callback) ->
    queryOptions = targetOptions: selector: { tags }
    plan.fetchProducts null, queryOptions, (err, products) ->
      return callback err  if err
      unless products?.length
        return callback message: "no products found"

      callback null, products[0].planCode

  @getCalculationOptions = (plan, planOptions) ->
    { userQuantity, resourceQuantity } = planOptions
    {
      plan
      userQuantity
      resourceQuantity
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

    subscribeToPlan.call this, client, options, (err, subscription) ->
      return callback err  if err
      JPaymentPack.one tags: "group", (err, pack) ->
        return callback err  if err
        subscription.debit {pack, shouldCreateNonce: yes}, (err, nonceStr) ->
          return callback err  if err
          JPaymentFulfillmentNonce.one nonce:nonceStr, (err, nonce) ->
            return callback err  if err
            return callback "nonce not found"  unless nonce
            nonce.addOwner client.connection.delegate, (err) ->
              callback err, subscription, nonce.nonce
