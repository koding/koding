{ Module } = require 'jraphical'

module.exports = class JPaymentBase extends Module

  { dash }  = require 'bongo'
  recurly   = require 'koding-payment'

  { Relationship } = require 'jraphical'

  { permit } = require '../group/permissionset'

  @create$ = permit 'manage products',
    success: (client, formData, callback) ->
      @create client.context.group, formData, callback

  @removeByCode = (planCode, callback) ->
    @one { planCode }, (err, product) ->
      return callback err  if err

      unless product?
        return callback { message: 'Unrecognized product code', planCode }

      product.remove callback

  @removeByCode$ = permit 'manage products',
    success: (client, planCode, callback) -> @removeByCode planCode, callback

  remove: (callback) ->
    { planCode } = this
    super (err) ->
      if err
        callback err
      else if planCode?
        recurly.deletePlan { planCode }, (err) ->
          return callback err  if err and err.short isnt 'not_found'

          callback null
      else
        callback null

  remove$: permit 'manage products',
    success: (client, callback) -> @remove callback

  modify: (formData, callback) ->
    @update { $set: formData }, callback

  modify$: permit 'manage products',
    success: (client, formData, callback) -> @modify formData, callback

  updateProducts: (quantities, callback) ->
    JPaymentProduct = require './product'

    planCodes = Object.keys quantities
    productSelector = { planCode: { $in: planCodes } }

    for planCode in planCodes
      quantities[planCode] = +quantities[planCode]

    JPaymentProduct.some productSelector, { limit: 20 }, (err, products) =>
      return callback err  if err

      if products.length isnt planCodes.length
        planCodesMap = planCodes.reduce( (acc, planCode) ->
          acc[planCode] = yes
          acc
        , {})
        products.forEach (product) ->
          if planCodesMap.hasOwnProperty product.planCode
            delete planCodesMap[product.planCode]
        return callback {
          message           : 'Unknown plan codes!'
          unknownPlanCodes  : Object.keys planCodesMap
        }

      Relationship.remove {
        sourceId    : @getId()
        targetName  : 'JPaymentProduct'
      }, (err) =>
        return callback err  if err

        queue = products.map (product) => =>
          @addProduct product, (err) -> queue.fin err

        dash queue, (err) =>
          return callback err  if err
          @modify { quantities }, (err) -> callback err

  updateProducts$: permit 'manage products',
    success: (client, quantities, callback) ->
      @updateProducts quantities, callback

  fetchProducts$: ->
    switch arguments.length
      when 1
        [callback] = arguments
      when 2
        [selector, callback] = arguments
      when 3
        [selector, options, callback] = arguments

    selector ?= {}
    options ?= {}

    if options.targetOptions
      { options, targetOptions } = options

    targetOptions ?= {}
    targetOptions.options ?= {}
    targetOptions.options.sort ?= { sortWeight: 1 }

    @fetchProducts selector, { options, targetOptions }, callback


