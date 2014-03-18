jraphical = require 'jraphical'
module.exports = class JKite extends jraphical.Module
  {permit}            = require './group/permissionset'
  {secure, signature} = require 'bongo'
  JKitePlan           = require './kiteplan'
  JAccount            = require './account'
  KodingError         = require '../error'
  {Relationship}      = jraphical

  @share()
  @set
    permissions           :
      'create kite'       : ['member']
      'list kites'        : ['member']
    schema                :
      name                : String
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedEvents          :
      instance            : []
      static              : []
    sharedMethods         :
      static:
        create:
          (signature Object, Function)
        list:
          (signature Object, Object, Function)
      instance:
        modify:
          (signature Object, Function)
        deleteKite:
          (signature Function)
        fetchSubscriptions:
          (signature Function)
        fetchPlans:
          (signature Function)
        removePlan:
          (signature Object, Function)

    relationships: ->
      plan          :
        as          : 'kitePlan'
        targetType  : JKitePlan

  @create: permit 'create kite',
    success:(client, formData, callback)->
      kite = new JKite formData
      kite.save (err)->
        return  callback new KodingError "kite couldn't saved" if err
        account = client.connection.delegate
        account.addKite (err, res)->
          return  callback new KodingError "kite couldn't added to Account" if err
          callback null, kite

  @list: permit 'list kites',
    success: (client, selector, options, callback)->
      JKite.some selector, options, callback

  modify: permit 'edit kite',
    success: (client, formData, callback)->
      console.log  "NOT IMPLEMENTED YET"

  deleteKite : permit 'delete kite',
    success: (client, callback)->
      console.log  "NOT IMPLEMENTED YET"

  fetchSubscriptions: permit 'fetch subscriptions',
    success: (client, callback)->
      console.log "NOT IMPLEMENTED YET"

  fetchKitePlans: permit 'fetch kite plans',
    success: (client, callback)->
      console.log  "NOT IMPLEMENTED YET"

  removePlan: permit 'modify kite',
    success: (client, callback )->
      console.log  "NOT IMPLEMENTED YET"

