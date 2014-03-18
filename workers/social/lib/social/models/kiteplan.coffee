jraphical = require 'jraphical'
module.exports = class JKitePlan extends jraphical.Module
  {permit}            = require './group/permissionset'
  {secure, signature} = require 'bongo'
  KodingError         = require '../error'
  JKite               = require './kite'
  {Relationship}      = jraphical

  @share()
  @set
    permissions           :
      'list kite plans'   : ['member']
      'create kite plans' : ['member']
    schema                :
      name                : String
      description         : String
      price               : String
      recurring           : String
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedEvents          :
      instance            : []
      static              : []
    sharedMethods         :
      static:
        list:
          (signature Object, Object, Function)
        create:
          (signature Object, Function)
      instance :
        modify :
          (signature Object, Function)

  @create: permit 'create kite plans',
    success:(client, formData, callback)->
      account  = client.connection.delegate
      {kiteId} = formData

      Relationship.one {
        targetName  : "JKite"
        targetId    : kiteId
        sourceName  : "JAccount"
        sourceId    : account.getId()
        as          : "owner"
      }, (err, rel) =>
        return  callback new KodingError err if err or not rel
        rel.fetchTarget (err, kite) =>
          kitePlan = new JKitePlan formData
          kitePlan.save (err)->
            return  callback new KodingError err if err
            kite.addPlan kitePlan, (err, res)->
              return  callback new KodingError err if err
              callback null, kitePlan

  modify: permit 'edit kite plan',
    success:(client, formData, callback)->
      {kiteId} = formData
      Relationship.one {
        targetName  : "JKite"
        targetId    : kiteId
        sourceName  : "JAccount"
        sourceId    : account.getId()
        as          : "owner"
      }, (err, rel) ->
        return  callback new KodingError err if err or not rel
        updatedFields =
          name        : formData.name
          price       : formData.price
          description : formData.description
          recurring   : formData.recurring

        @update $set: updatedFields , callback

  deletePlan: permit 'delete kite plan',
    success:(client, callback)->
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




