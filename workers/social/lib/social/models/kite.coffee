jraphical = require 'jraphical'
module.exports = class JKite extends jraphical.Module

  KodingError         = require '../error'
  { permit }          = require './group/permissionset'
  { signature }       = require 'bongo'
  { Relationship }    = jraphical
  { v4: createId }    = require 'node-uuid'

  @trait __dirname, '../traits/protected'

  @share()
  @set
    permissions           :
      'create kite'       : ['member']
      'list kites'        : ['member']
    schema                :
      name                : String
      manifest            : Object
      kiteCode            : String
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedEvents          :
      instance            : []
      static              : []
    sharedMethods         :
      static              :
        create            :
          (signature Object, Function)
        list              :
          (signature Object, Object, Function)
      instance            :
        modify            :
          (signature Object, Function)
        deleteKite        :
          (signature Function)
        fetchPlans        :
          (signature Function)
        createPlan        :
          (signature Object, Function)
        deletePlan        :
          (signature Object, Function)

  @create: permit 'create kite',
    success: (client, formData, callback) ->
      { delegate } = client.connection
      { profile }  = delegate

      formData.manifest.authorNick = profile.nickname
      formData.manifest.author     = "#{profile.firstName} #{profile.lastName}"

      kite = new JKite formData
      kite.kiteCode = createId()

      kite.save (err) ->
        return  callback new KodingError "kite couldn't saved" if err

        delegate.addKite kite, (err, res) ->
          return  callback new KodingError "kite couldn't added to account" if err
          callback null, kite

  @list: permit 'list kites',
    success: (client, selector, options, callback) ->
      JKite.some selector, options, (err, kites) ->
        delete kite.data.kiteCode  for kite in kites
        callback err, kites

  modify: permit 'edit kite',
    success: (client, formData, callback) ->
      @update { $set: { name: formData.name, description: formData.description } }, callback

  deleteKite: permit 'delete kite',
    success: (client, callback) ->
      account = client.connection.delegate
      Relationship.one {
        targeName   : 'JKite'
        targetId    : @getId()
        sourceName  : 'JAccount'
        sourceId    : account.getId()
        as          : 'owner'
      }, (err, rel) =>
        return  callback new KodingError err if err
        if rel
          @remove (err, res) ->
            return  callback err, res

  createPlan: permit 'create kite',
    success: (client, formData, callback) ->
      { userTag } = formData
      formData.tags = ['kite', userTag]
      JPaymentPlan  = require './payment/plan'
      JPaymentPlan.create client.context.group, formData, (err, plan) =>
        return  callback err if err
        @addPlan plan, callback

  deletePlan: permit 'delete kite plan',
    success: (client, planCode, callback) ->
      @fetchPlans (err, plan) ->
        plan.remove


