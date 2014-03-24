JPaymentBase = require './base'

module.exports = class JPaymentProduct extends JPaymentBase

  { signature } = require 'bongo'

  { v4: createId } = require 'node-uuid'
  recurly = require 'koding-payment'

  { permit } = require '../group/permissionset'

  @share()

  @set
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods     :
      static          :
        create        :
          (signature Object, Function)
        removeByCode  :
          (signature String, Function)
        some          :
          (signature Object, Object, Function)
      instance        :
        remove        :
          (signature Function)
        modify        :
          (signature Object, Function)
    schema            :
      planCode        :
        type          : String
        required      : yes
      title           :
        type          : String
        required      : yes
      description     : String
      subscriptionType:
        type          : String
        default       : 'recurring'
      feeAmount       :
        type          : Number
        validate      : (require './validators').fee
      feeInitial      :
        type          : Number
        validate      : (require './validators').fee
      feeInterval     :
        type          : Number
        default       : 1
      feeUnit         : (require './schema').feeUnit
      overageEnabled  :
        type          : Boolean
        default       : no
      soldAlone       :
        type          : Boolean
        default       : no
      priceIsVolatile :
        type          : Boolean
        default       : no
      group           :
        type          : String
        required      : yes
      tags            : (require './schema').tags
      sortWeight      : Number

  @create = (group, formData, callback) ->

    JGroup = require '../group'

    { subscriptionType, overageEnabled, soldAlone,
      priceIsVolatile, title, description, feeAmount,
      feeUnit, feeInterval, tags } = formData

    product = new this {
      planCode: createId()
      title
      description
      feeAmount
      feeUnit
      feeInterval
      subscriptionType
      priceIsVolatile
      overageEnabled
      soldAlone
      group
      tags
    }

    product.save (err) =>
      return callback err  if err

      product.savePlanToRecurly (err, plan) ->
        return callback err  if err

        JGroup.one slug: group, (err, group) ->
          return callback err  if err

          group.addProduct product, (err) ->
            return callback err  if err

            callback null, product

  savePlanToRecurly: (callback) ->
    if not @priceIsVolatile and @overageEnabled or @soldAlone

      planData =
        planCode    : @planCode
        title       : "#{ @title } - Overage"
        feeAmount   : @feeAmount
        feeInterval : switch @subscriptionType
          when 'recurring' then 1
          when 'single'    then 9999 # wat

      recurly.createPlan planData, callback

    else process.nextTick -> callback null
