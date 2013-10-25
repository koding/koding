{ Module } = require 'jraphical'

module.exports = class JPaymentProduct extends Module

  createId = require 'hat'
  recurly = require 'koding-payment'

  { permit } = require '../group/permissionset'

  @share()

  @set
    sharedMethods     :
      static          : [
        'create'
        'removeByCode'
      ]
      instance        : [
        'remove'
      ]
    schema            :
      title           :
        type          : String
        required      : yes
      description     : String
      subscriptionType: String
      amount          :
        type          : Number
        required      : yes
      overageEnabled  : Boolean
      planCode        : String
      group           : String

  @create = (group, formData, callback) ->

    JGroup = require '../group'

    { type: subscriptionType, overageEnabled, title, description,
      amount } = formData

    product = new this {
      title
      description
      amount            : amount * 100
      subscriptionType  : subscriptionType ? 'recurring'
      planCode          : createId()
      overageEnabled    : overageEnabled is 'on'
      group
    }

    product.save (err) =>
      return callback err  if err

      @savePlanToRecurly product, (err, plan) ->
        return callback err  if err

        JGroup.one slug: group, (err, group) ->
          return callback err  if err

          group.addProduct product, (err) ->
            return callback err  if err

            callback null, product

  @create$ = permit 'manage products',
    success: (client, formData, callback) ->
      @create client.context.group, formData, callback

  @savePlanToRecurly = (product, callback) ->
    if product.overageEnabled

      planData =
        code        : product.planCode
        title       : "#{ product.title } - Overage"
        feeMonthly  : product.amount
        feeInterval : switch product.subscriptionType
          when 'recurring' then 1
          when 'single'    then 9999 # wat

      recurly.createPlan planData, callback

    else process.nextTick -> callback null

  @removeByCode = (planCode, callback) ->
    @one { planCode }, (err, product) ->
      return callback err  if err

      unless product?
        return callback { message: 'Unrecognized product code', planCode }

      product.remove callback

  @removeByCode$ = permit 'manage products',
    success: (client, planCode, callback) -> @removeByCode planCode, callback

  remove: (callback) ->
    { planCode: code, overageEnabled } = this
    super (err) ->
      if err
        callback err
      else if code? and overageEnabled
        recurly.deletePlan { code }, callback
      else
        callback null

  remove$: permit 'manage products',
    success: (client, callback) -> @remove callback