jraphical      = require 'jraphical'

module.exports = class JCredential extends jraphical.Module

  JName              = require '../name'
  JUser              = require '../user'
  JGroup             = require '../group'
  JCredentialData    = require './credentialdata'
  { PROVIDERS }      = require './computeutils'

  KodingError        = require '../../error'

  { secure, ObjectId, signature, daisy } = require 'bongo'
  { Relationship }     = jraphical
  { permit }           = require '../group/permissionset'
  Validators           = require '../group/validators'

  @trait __dirname, '../../traits/protected'

  @share()

  @set

    softDelete        : yes

    permissions       :
      'modify credential' : []
      'create credential' : ['member']
      'update credential' : ['member']
      'list credentials'  : ['member']
      'delete credential' : ['member']

    sharedMethods     :
      static          :
        one           :
          (signature String, Function)
        create        :
          (signature Object, Function)
        some          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
      instance        :
        delete        :
          (signature Function)
        clone         :
          (signature Function)
        shareWith     :
          (signature Object, Function)
        fetchUsers    :
          (signature Function)
        fetchData     :
          (signature Function)
        update        :
          (signature Object, Function)
        isBootstrapped:
          (signature Function)

    sharedEvents      :
      static          : [ ]
      instance        : [
        { name : 'updateInstance' }
      ]

    indexes           :
      identifier      : 'unique'
      fields          : 'sparse'

    schema            :

      provider        :
        type          : String
        required      : yes

      title           :
        type          : String
        required      : yes

      identifier      :
        type          : String
        required      : yes

      originId        :
        type          : ObjectId
        required      : yes

      meta            : require 'bongo/bundles/meta'

      fields          :
        type          : [String]
        default       : -> []

      verified        :
        type          : Boolean
        default       : -> no

    relationships     :

      data            :
        targetType    : JCredentialData
        as            : 'data'

  @getName = -> 'JCredential'

  failed = (err, callback, rest...) ->
    return false  unless err

    if rest
      obj.remove?()  for obj in rest

    callback err
    return true


  @create = permit 'create credential',

    success: (client, data, callback) ->

      { delegate } = client.connection
      { provider, title, meta } = data
      originId = delegate.getId()

      if provider not in ['custom', 'userInput'] and not PROVIDERS[provider]?
        callback new KodingError 'Provider is not supported'
        return

      credData = new JCredentialData { meta, originId }
      credData.save (err) ->
        return  if failed err, callback

        { identifier }   = credData
        _data            = { provider, title, identifier, originId }

        if provider in ['custom', 'userInput']
          _data.fields   = (Object.keys meta) or []
          _data.verified = yes

        credential = new JCredential _data

        credential.save (err) ->
          return  if failed err, callback, credData

          delegate.addCredential credential, { as: 'owner' }, (err) ->
            return  if failed err, callback, credential, credData

            credential.addData credData, (err) ->
              return  if failed err, callback, credential, credData
              callback null, credential


  @fetchByIdentifier = (client, identifier, callback) ->

    options =
      limit         : 1
      targetOptions :
        selector    : { identifier }

    { delegate } = client.connection
    delegate.fetchCredential {}, options, (err, res) ->

      return callback err        if err?
      return callback null, res  if res?

      { group } = client.context
      JGroup.one { slug: group }, (err, group) ->
        return callback err  if err?

        group.fetchCredential {}, options, (err, res) ->
          callback err, res


  @one$ = permit 'list credentials',

    success: (client, identifier, callback) ->

      @fetchByIdentifier client, identifier, callback


  @some$ = permit 'list credentials',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection
      items        = []

      relSelector  =
        targetName : 'JCredential'
        sourceId   : delegate.getId()

      if selector.as? and selector.as in ['owner', 'user']
        relSelector.as = selector.as
        delete selector.as

      Relationship.someData relSelector, { targetId:1, as:1 }, (err, cursor) =>

        return callback err  if err?

        cursor.toArray (err, arr) =>

          map = arr.reduce (memo, doc) ->
            memo[doc.targetId] = doc.as
            memo
          , {}

          selector    ?= {}
          selector._id = { $in: (t.targetId for t in arr) }

          @some selector, options, (err, items) ->
            return callback err  if err?

            for item in items
              item.owner = map[item._id] is 'owner'

            callback null, items


  fetchUsers: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      Relationship.someData { targetId : @getId() }, {
        as:1, sourceId:1, sourceName:1
      }, (err, cursor) ->

        return callback err  if err?

        cursor.toArray (err, arr) ->
          return callback err  if err?

          if arr.length > 0
            callback null, ({
              constructorName : u.sourceName
              _id : u.sourceId
              as  : u.as
            } for u in arr)
          else
            callback null, []


  setPermissionFor: (target, { user, owner }, callback) ->

    Relationship.remove
      targetId : @getId()
      sourceId : target.getId()
    , (err) =>

      if user
        as = if owner then 'owner' else 'user'
        target.addCredential this, { as }, (err) -> callback err
      else
        callback err


  shareWith: (client, options, callback) ->

    { delegate } = client.connection
    { target, user, owner } = options
    user ?= yes

    # Owners cannot unassign them from a credential
    # Only another owner can unassign any other owner
    if delegate.profile.nickname is target
      return callback null

    JName.fetchModels target, (err, result) =>

      if err or not result
        return callback new KodingError 'Target not found.'

      { models } = result
      [ target ] = models

      if target instanceof JUser
        target.fetchOwnAccount (err, account) =>
          if err or not account
            return callback new KodingError 'Failed to fetch account.'
          @setPermissionFor account, { user, owner }, callback

      else if target instanceof JGroup
        @setPermissionFor target, { user, owner }, callback

      else
        callback new KodingError 'Target does not support credentials.'


  # .share can be used like this:
  #
  # JCredentialInstance.share { user: yes, owner: no, target: "gokmen"}, cb
  #                                      group or user slug -> ^^^^^^

  shareWith$: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: JCredential::shareWith


  delete: permit 'delete credential',

    success: (client, callback) ->

      { delegate } = client.connection

      Relationship.one {
        targetId : @getId()
        sourceId : delegate.getId()
      }, (err, rel) =>

        return callback err   if err?
        return callback null  unless rel?

        if rel.data.as is 'owner'

          @fetchData (err, credentialData) =>
            return callback err  if err
            credentialData.remove (err) =>
              return callback err  if err
              @remove callback

        else

          rel.remove callback


  clone: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      { delegate } = client.connection

      cloneData  =
        title    : @getAt 'title'
        provider : @getAt 'provider'

      @fetchData (err, data) ->

        return callback err  if err

        cloneData.meta = data.meta  if data?.meta
        JCredential.create client, cloneData, callback

      , shadowSensitiveData = no


  # Poor man's shadow function ~ GG
  shadowed = (c) ->
    return  unless c
    r = (c) -> Math.ceil c.length / 1.5
    return "*#{Array(r c).join '*'}#{c[(r c)..]}"


  fetchData: (callback, shadowSensitiveData = yes) ->

    sensitiveKeys = PROVIDERS[@provider]?.sensitiveKeys or []

    Relationship.one { sourceId: @getId(), as: 'data' }, (err, rel) ->

      return callback err  if err
      return callback new KodingError 'No data found'  unless rel

      rel.fetchTarget (err, data) ->
        return callback err  if err

        if shadowSensitiveData
          meta = data?.data?.meta or {}
          sensitiveKeys.forEach (key) ->
            meta[key] = shadowed meta[key]

        callback null, data


  fetchData$: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      @fetchData callback


  update$: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, options, callback) ->

      { title, meta } = options

      unless title or meta
        return callback new KodingError 'Nothing to update'

      title ?= @title

      @update { $set : { title } }, (err) =>
        return callback err  if err?

        if meta?

          @fetchData (err, credData) ->
            return callback err  if err?
            credData.update { $set : { meta } }, callback

        else
          callback null


  isBootstrapped: permit

    advanced: [
      { permission: 'modify credential' }
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      provider = PROVIDERS[@provider]

      unless provider
        return callback null, no

      { bootstrapKeys } = provider

      # If bootstrapKeys is not defined in the Provider
      # it means that this credential is not supporting bootstrap
      # we can safely return `no` at this point ~ GG
      if bootstrapKeys.length is 0
        return callback null, no

      @fetchData (err, data) ->
        return callback err  if err
        return callback new KodingError 'Failed to fetch data'  unless data

        verifiedCount = 0
        bootstrapKeys.forEach (key) ->
          verifiedCount++  if data['meta']?[key]?

        callback null, bootstrapKeys.length is verifiedCount


