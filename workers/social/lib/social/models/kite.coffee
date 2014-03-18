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
          return  callback new KodingError "kite couldn't added to account" if err
          callback null, kite

  @list: permit 'list kites',
    success: (client, selector, options, callback)->
      JKite.some selector, options, callback

  modify: permit 'edit kite',
    success: (client, formData, callback)->
      @update $set: {name: formData.name} , callback

  deleteKite : permit 'delete kite',
    success: (client, callback)->
      account = client.connection.delegate
      Relationship.one {
        targeName   : "JKite"
        targetId    : @getId()
        sourceName  : "JAccount"
        sourceId    : account.getId()
        as          : "owner"
      }, (err, rel) =>
        return  callback new KodingError err if err
        @remove (err, res)->
          return  callback err, res

