{ Module } = require 'jraphical'

module.exports = class JPaymentBase extends Module

  { permit } = require '../group/permissionset'

  recurly = require 'koding-payment'

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
        recurly.deletePlan { planCode }, callback
      else
        callback null

  remove$: permit 'manage products',
    success: (client, callback) -> @remove callback

  modify: (formData, callback) ->
    @update $set: formData, callback

  modify$: permit 'manage products',
    success: (client, formData, callback) -> @modify formData, callback
