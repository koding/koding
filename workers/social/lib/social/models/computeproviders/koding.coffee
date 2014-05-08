
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'
JVM               = require '../vm'

{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface


  @processNonce = (nonce, callback)->

    unless nonce
      return callback new KodingError
        message : "Payment requirements missing."

    JPaymentFulfillmentNonce  = require '../payment/nonce'
    JPaymentSubscription      = require '../payment/subscription'
    JPaymentPack              = require '../payment/pack'

    JPaymentFulfillmentNonce.one { nonce }, (err, nonceObject)->

      return callback err  if err

      unless nonceObject
        return callback message: "Unrecognized nonce!", nonce

      if nonceObject.action isnt "debit"
        return callback message: "Invalid nonce!", nonce

      { subscriptionCode } = nonceObject

      JPaymentSubscription.isFreeSubscripton subscriptionCode, \
      (err, isFreeSubscripton)=>
        return callback err if err

        nonceObject.update $set: action: "used", (err) =>
          return callback err  if err

          callback null, { isFreeSubscripton, nonceObject }


  @generateAliases = ({nickname, type, group})->

    domain = 'kd.io'
    type  ?= 'user'
    uid    = (require 'hat')(16)

    if type is 'user'

      aliases = ["vm-#{uid}.#{nickname}.#{group}.#{domain}"
                 "vm-#{uid}.#{nickname}.#{domain}"
                 "#{nickname}.#{group}.#{domain}"
                 "#{nickname}.#{domain}"]

    else if type is 'shared'

      aliases = ["shared-#{uid}.#{group}.#{domain}"
                 "shared.#{group}.#{domain}"
                 "#{group}.#{domain}"]

    return aliases ? []


  @ping = (client, callback)->

    callback null, "Koding is the best #{ client.connection.delegate.profile.nickname }!"


  @fetchExisting = (client, options, callback)->

    JVM.fetchVmsByContext client, options, callback


  @create = (client, options, callback)->

    { connection:{delegate:account}, context:{group} } = client
    { nickname } = account.profile

    { nonce }    = options

    @processNonce nonce, (err, details)=>

      return callback err  if err?

      { isFreeSubscripton, nonceObject } = details
      { planCode, subscriptionCode } = nonceObject

      hostnameAliases = @generateAliases { group, nickname }
      hostnameAlias   = hostnameAliases[0]

      meta = {
        planCode
        hostnameAlias
        subscriptionCode
        webHome : nickname
        vmType  : "user"
      }

      unless isFreeSubscripton
        meta.region = KONFIG.regions.premium

      callback null, {
        postCreateOptions: { hostnameAliases, account, group }
      , meta }



  @remove = (client, options, callback)->

    {hostnameAlias} = options
    JVM.removeByHostname client, hostnameAlias, callback


  @update = (client, options, callback)->

    callback new KodingError \
      "Update not supported for Koding VMs", "NotSupported"


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "small"
        title : "Small 1x"
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
      {
        name  : "large"
        title : "Large 2x"
        spec  : {
          cpu : 2, ram: 2, storage: 8
        }
      }
      {
        name  : "extra-large"
        title : "Extra Large 4x"
        spec  : {
          cpu : 4, ram: 4, storage: 16
        }
      }
    ]