{Module} = require 'jraphical'

module.exports = class JPaymentProduct extends Module

  createId = require 'hat'
  recurly = require 'koding-payment'

  { permit } = require '../group/permissionset'

  @share()

  @set
    sharedMethods :
      static      : ['create']
      instance    : ['remove']
    schema        :
      title       : String
      description : String
      amount      : Number
      planCode    : String

  @create = (group, formData, callback) ->

    JGroup = require '../group'

    product = new this formData
    product.planCode = createId()

    product.save (err) ->
      return callback err  if err

      planData =
        code        : product.planCode
        title       : "#{ product.title } - Overage"
        feeMonthly  : product.amount

      recurly.createPlan planData, (err, plan) ->
        return callback err  if err

        JGroup.one { slug: group }, (err, group) ->
          return callback err  if err

          group.addProduct product, (err) ->
            return callback err  if err

            callback null, product

  remove: permit 'manage products',
    success: (client, callback) ->
      Module::remove.call this, (err) =>
        return callback err  if err

        recurly.deletePlan @planCode, callback

  @create$ = permit 'manage products',
    success: (client, formData, callback) ->
      @create client.context.group, formData, callback