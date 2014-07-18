
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'
JVM               = require '../vm'

{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface

  VMDefaultDiskSize = @VMDefaultDiskSize = 3072

  # This is currently using payment method
  # we will not use it any longer, for a reference keeping it
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


  @ping = (client, options, callback)->

    callback null, "Koding is the best #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback)->

    { instanceType } = options

    # @fetchCredentialData credential, (err, cred)->
    #   return callback err  if err?

    meta =
      type          : "amazon"
      region        : "us-east-1"
      source_ami    : "ami-a6926dce"
      instance_type : instanceType

    callback null, { meta, credential: client.r.user.username }

  # @create = (client, options, callback)->

  #   { r: { account, group } } = client
  #   { nickname } = account.profile

  #   group = group.slug

  #   hostnameAliases = @generateAliases { group, nickname }
  #   hostnameAlias   = hostnameAliases[0]
  #   region          = if argv.c is 'vagrant' then 'vagrant' else 'sj'
  #   { freeVM }      = KONFIG.defaultVMConfigs

  #   meta = {
  #     region
  #     hostnameAlias
  #     maxMemoryInMB : freeVM.ram ? 1024
  #     diskSizeInMB  : freeVM.storage ? VMDefaultDiskSize
  #     ldapPassword  : null
  #     hostKite      : null
  #     alwaysOn      : no
  #     numCPUs       : freeVM.cpu ? 1
  #     webHome       : nickname
  #     vmType        : "user"
  #     ip            : null
  #     meta          : {}
  #   }

  #   callback null, {
  #     meta,
  #     postCreateOptions: {
  #       hostnameAliases, account, group
  #     }
  #   }


  # @remove = (client, options, callback)->

  #   {hostnameAlias} = options
  #   JVM.removeByHostname client, hostnameAlias, callback


  # @update = (client, options, callback)->

  #   callback new KodingError \
  #     "Update not supported for Koding VMs", "NotSupported"


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "t2.micro"
        title : "Small 1x"
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
    ]