hat       = require 'hat'
jraphical = require 'jraphical'

module.exports = class JCredential extends jraphical.Module

  JName              = require '../name'
  JUser              = require '../user'
  JGroup             = require '../group'
  JCredentialData    = require './credentialdata'
  { PROVIDERS }      = require './computeutils'
  CredentialStore    = require './credentialstore'

  KodingError        = require '../../error'

  { secure, ObjectId, signature } = require 'bongo'
  { Relationship }     = jraphical
  { permit }           = require '../group/permissionset'
  Validators           = require '../group/validators'

  @ACCESSLEVEL = ACCESSLEVEL = {
    WRITE      : 'write'
    READ       : 'read'
    LIST       : 'list'
    PRIVATE    : 'private'
  }

  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/notifiable'

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
        bootstrap:
          (signature Function)
        isBootstrapped:
          (signature Function)

    sharedEvents      :
      static          : []
      instance        : []

    indexes           :
      identifier      : 'unique'
      fields          : 'sparse'
      accessLevel     : 'sparse'

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

      # accessLevel is defined for admins if a credential shared with
      # a group. scopes can be;
      #
      #  write   : allows admins to update this credential
      #  read    : allows admins to read credential data
      #  list    : allows admins to list this credential (some)
      #  private : even admins can not interact with this credential
      #            only owners of the credential can access/interact
      #
      #  write > read > list > private
      #
      #  if read used, admins can read but not update
      #  if write used, admins can read and update and so on.
      #
      accessLevel     :
        type          : String
        enum          : ['Wrong access level specified!',
          [
            ACCESSLEVEL.WRITE
            ACCESSLEVEL.READ
            ACCESSLEVEL.LIST
            ACCESSLEVEL.PRIVATE
          ]
        ]
        default       : -> ACCESSLEVEL.PRIVATE


  @getName = -> 'JCredential'

  failed = (err, callback, rest...) ->
    return false  unless err

    if rest
      obj.remove?()  for obj in rest

    callback err
    return true


  accessValidator = (accessLevel) -> (client, group, rest..., callback) ->

    # using any validator to check permission based on the role in the group
    Validators.any client, group, rest..., (err, allowed) =>

      # you first need to have access on the active group
      # if you are not allowed we stop here
      if err or not allowed
        return callback err, allowed

      deny = -> callback new KodingError 'Access denied'

      # if this is an old credential which doesn't have any accessLevel
      # defined on it, we are denying all requests to it
      return deny()  unless currentLevel = @getAt 'accessLevel'

      # if you have access then we need to check
      # if document allows provided accessLevel

      { WRITE, READ, LIST, PRIVATE } = ACCESSLEVEL

      return deny()  if currentLevel is PRIVATE

      switch accessLevel
        when WRITE
          return deny()  unless currentLevel is  WRITE
        when READ
          return deny()  unless currentLevel in [WRITE, READ]
        when LIST
          return deny()  unless currentLevel in [WRITE, READ, LIST]

      return callback null, yes


  @create = permit 'create credential',

    success: (client, data, callback) ->

      { delegate } = client.connection
      { provider, title, meta } = data
      originId = delegate.getId()

      if provider not in ['custom', 'userInput'] and not PROVIDERS[provider]?
        callback new KodingError 'Provider is not supported'
        return

      for field, value of meta
        meta[field] = value.trim()  if typeof value is 'string'
        delete meta[field]  if value is ''

      CredentialStore.create client, { meta, originId }, (err, identifier) ->
        return  if failed err, callback

        _data = { provider, title, identifier, originId }

        if provider in ['custom', 'userInput']
          _data.fields   = (Object.keys meta) or []
          _data.verified = yes

        credential = new JCredential _data

        credential.save (err) ->
          return  if failed err, callback

          delegate.addCredential credential, { as: 'owner' }, (err) ->
            return  if failed err, callback, credential

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


  fetchRolesAndGroup = (client, callback) ->

    try
      { context: { group: slug }, connection: { delegate } } = client
    catch e
      return callback new KodingError 'Insufficient arguments provided', e

    JGroup.one { slug }, (err, group) ->

      if err or not group
        err ?= new KodingError 'Group not found!'
        return callback err

      group.fetchRolesByAccount delegate, (err, roles = []) ->
        return callback err  if err

        callback err, { group, roles }


  fetchRelationships = ({ selector, group, delegate }, callback) ->

    relSelector = { targetName: 'JCredential' }
    relOptions  = { targetId: 1, sourceId: 1, as: 1 }

    if selector.as? and selector.as in ['owner', 'user']
      relSelector.as = selector.as
      delete selector.as

    # Find all the documents shared with the delegate or group ~ GG
    relSelector.sourceId = {
      $in: [ delegate.getId(), group.getId() ]
    }

    Relationship.someData relSelector, relOptions, (err, cursor) ->
      return callback err  if err?
      cursor.toArray callback


  @some$ = permit 'list credentials',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection
      items        = []

      fetchRolesAndGroup client, (err, res) =>
        return callback err  if err

        { group, roles } = res

        fetchRelationships { selector, group, delegate }, (err, rels) =>

          if err or not rels
            return callback err ? new KodingError 'Failed to fetch credentials'

          # if user doesn't have admin roles exclude all the items shared with
          # the group because regular users do not have rights to list those
          unless 'admin' in roles
            groupId = group.getId()
            rels    = rels.filter (rel) -> not groupId.equals rel.sourceId

          map = rels.reduce (memo, doc) ->
            memo[doc.targetId] ?= doc.as
            memo[doc.targetId]  = 'owner'  if doc.as is 'owner'
            memo
          , {}

          selector    ?= {}
          selector._id = { $in: (t.targetId for t in rels) }

          # exclude all private credentials from the list ~ GG
          selector.$and ?= []
          selector.$and  = [] unless Array.isArray selector.$and
          selector.$and.push {
            $or: [
              { originId    : delegate.getId() }
              { accessLevel : { $ne: ACCESSLEVEL.PRIVATE } }
            ]
          }

          @some selector, options, (err, items) ->
            return callback err  if err?

            for item in items
              item.owner = map[item._id] is 'owner'

            callback null, items


  fetchUsers: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.READ
      }
      { permission   : 'modify credential', superadmin: yes }
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


  setPermissionFor: (target, { user, owner, accessLevel }, callback) ->

    Relationship.remove
      targetId : @getId()
      sourceId : target.getId()
    , (err) =>

      if user
        options = { as: if owner then 'owner' else 'user' }
        if accessLevel
          @update { $set: { accessLevel } }, (err) =>
            return callback err  if err?
            target.addCredential this, options, callback
        else
          target.addCredential this, options, callback
      else
        callback err


  shareWith: (client, options, callback) ->

    { delegate } = client.connection
    { target, user, owner, accessLevel } = options
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
        @setPermissionFor target, { user, owner, accessLevel }, callback

      else
        callback new KodingError 'Target does not support credentials.'


  # .share can be used like this:
  #
  # JCredentialInstance.share { user: yes, owner: no, target: "gokmen"}, cb
  #                                      group or user slug -> ^^^^^^

  shareWith$: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.WRITE
      }
      { permission   : 'modify credential', superadmin: yes }
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

          CredentialStore.remove client, @identifier, (err) =>
            return callback err  if err
            @remove (err) -> callback err

        else

          rel.remove callback


  clone: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.READ
      }
      { permission   : 'modify credential', superadmin: yes }
    ]

    success: (client, callback) ->

      { delegate } = client.connection

      cloneData  =
        title    : @getAt 'title'
        provider : @getAt 'provider'

      options =
        shadowSecretData    : no
        shadowSensitiveData : no

      @fetchData client, options, (err, data) ->

        return callback err  if err

        cloneData.meta = data.meta  if data?.meta
        JCredential.create client, cloneData, callback


  # Poor man's shadow function ~ GG
  shadowed = (c) ->
    return ''  unless c
    return Array(30).join '*'  if c.length > 100
    c = c[0...x = (Math.min  c.length, 100)]
    r = Math.ceil c.length / 3
    return "#{c[..r]}..."


  fetchData: (client, options, callback) ->

    { shadowSensitiveData, shadowSecretData } = options

    shadowSensitiveData ?= yes
    shadowSecretData    ?= yes

    secretKeys    = PROVIDERS[@provider]?.secretKeys    or []
    sensitiveKeys = PROVIDERS[@provider]?.sensitiveKeys or []

    CredentialStore.fetch client, @identifier, (err, data) ->

      return callback err  if err

      if shadowSensitiveData
        meta = data?.meta or {}
        sensitiveKeys.forEach (key) ->
          meta[key] = shadowed meta[key]

      if shadowSecretData
        meta = data?.meta or {}
        secretKeys.forEach (key) ->
          meta[key] = shadowed meta[key]

      callback null, data


  fetchData$: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.READ
      }
      { permission   : 'modify credential', superadmin: yes }
    ]

    success: (client, callback) ->

      options =
        shadowSecretData    : yes
        shadowSensitiveData : yes

      if client._allowedPermissionIndex is 0
        options.shadowSensitiveData = no

      @fetchData client, options, callback


  update$: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.WRITE
      }
      { permission   : 'modify credential', superadmin: yes }
    ]

    success: (client, options, callback) ->

      { context: { group }, connection: { delegate: account } } = client
      { title, meta } = options

      unless title or meta
        return callback new KodingError 'Nothing to update'

      title ?= @title

      if @provider in ['custom', 'userInput']
        fields = if meta then (Object.keys meta) else []

      notifyOptions =
        account : account
        group   : group
        target  : 'account'

      @updateAndNotify notifyOptions, { $set : { title, fields } }, (err) =>
        return callback err  if err?

        if meta?
          CredentialStore.update client, { @identifier, meta }, callback
        else
          callback null


  getProvider: -> PROVIDERS[@getAt 'provider']


  isBootstrapped: permit

    advanced: [
      { permission: 'update credential' }
    ]

    success: (client, callback) ->

      unless provider = @getProvider()
        return callback null, no

      { bootstrapKeys } = provider

      # If bootstrapKeys is not defined in the Provider
      # it means that this credential is not supporting bootstrap
      # we can safely return `no` at this point ~ GG
      if bootstrapKeys.length is 0
        return callback null, no

      @fetchData client, {}, (err, data) ->
        return callback err  if err
        return callback new KodingError 'Failed to fetch data'  unless data

        verifiedCount = 0
        bootstrapKeys.forEach (key) ->
          verifiedCount++  if data['meta']?[key]?

        callback null, bootstrapKeys.length is verifiedCount


  bootstrap: permit

    advanced: [
      { permission   : 'update credential', validateWith: Validators.own }
      {
        permission   : 'modify credential'
        validateWith : accessValidator ACCESSLEVEL.WRITE
      }
      { permission   : 'modify credential', superadmin: yes }
    ]

    success: (client, callback) ->

      unless provider = @getProvider()
        return callback new KodingError 'Provider does not support bootstrap'

      provider    = provider.providerSlug
      identifiers = [@getAt 'identifier']

      Kloud = require './kloud'
      Kloud.bootstrap client, { identifiers, provider }, callback
