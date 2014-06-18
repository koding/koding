
jraphical   = require 'jraphical'
JName       = require '../name'
JUser       = require '../user'
JGroup      = require '../group'
JCredential = require './credential'

module.exports = class JProvisioner extends jraphical.Module

  KodingError        = require '../../error'

  {secure, ObjectId, signature, daisy} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require '../group/permissionset'
  Validators         = require '../group/validators'

  @trait __dirname, '../../traits/protected'

  @share()

  @set

    softDelete        : yes

    permissions       :
      'create provisioner' : ['member']
      'update provisioner' : ['member']
      'list provisioners'  : ['member']
      'delete provisioner' : ['member']

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
        shareWith     :
          (signature Object, Function)
        fetchUsers    :
          (signature Function)
        fetchData     :
          (signature Function)
        update        :
          (signature Object, Function)

    sharedEvents      :
      static          : [ ]
      instance        : [
        { name : 'updateInstance' }
      ]

    indexes           :
      slug            : 'unique'

    schema            :

      slug            :
        type          : String
        required      : yes

      label           : String

      type            :
        type          : String
        enum          : ["Wrong type specified!", [

          # Provisioner types which supported by packer.io and kloud
          #
          "shell"     # Shell script

        ]]

        default       : -> "shell"

      content         :
        type          : Object
        default       : -> { }

      meta            : require 'bongo/bundles/meta'


  checkContent = (type, content)->

    if not type?
      err = "Type missing."
    else if not content?
      err = "Content missing."
    else
      switch type
        when "shell"
          unless content.script?
          then err = "Type 'shell' requires a 'script'"
          else content = { script: content.script }
        else
          err = "Type is not supported for now."

    err = new KodingError err  if err?
    return [err, content]

  fetchUsers: JCredential::fetchUsers

  @create = permit 'create provisioner',

    success: (client, data, callback)->

      {delegate} = client.connection
      {content, type, label} = data

      [err, content] = checkContent type, content
      if err? then return callback err

      slug = "#{delegate.profile.nickname}-#{(require 'hat')(32)}"

      provisioner = new JProvisioner {
        slug, label, content, type
      }

      provisioner.save (err)->

        return callback err  if err

        delegate.addProvisioner provisioner, as: "owner", (err)->

          if err
            provisioner.remove?()
            callback err
          else
            callback null, provisioner


  @fetchBySlug = (client, slug, callback)->

    options =
      limit         : 1
      targetOptions : selector : { slug }

    {delegate} = client.connection
    delegate.fetchProvisioner { }, options, (err, res)->

      return callback err        if err?
      return callback null, res  if res?

      { group } = client.context
      JGroup.one slug: group, (err, group)->
        return callback err  if err?

        group.fetchProvisioner { }, options, (err, res)->
          callback err, res


  @one$: permit 'list provisioners',

    success: (client, slug, callback)->

      @fetchBySlug client, slug, callback


  @some$: permit 'list provisioners',

    success: (client, selector, options, callback)->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection
      provisioners  = []

      relSelector  =
        targetName : "JProvisioner"
        sourceId   : delegate.getId()

      if selector.as? and selector.as in ['owner', 'user']
        relSelector.as = selector.as
        delete selector.as

      Relationship.someData relSelector, { targetId:1, as:1 }, (err, cursor)->

        return callback err  if err?

        cursor.toArray (err, arr)->

          map = arr.reduce (memo, doc)->
            memo[doc.targetId] = doc.as
            memo
          , {}

          selector    ?= {}
          selector._id = $in: (t.targetId for t in arr)

          JProvisioner.some selector, options, (err, provisioners)->
            return callback err  if err?

            for provisioner in provisioners
              provisioner.owner = yes  if map[provisioner._id] is 'owner'

            callback null, provisioners


  # .share can be used like this:
  #
  # JProvisionerInstance.share { user: yes, owner: no, target: "gokmen"}, cb
  #                                       group or user slug -> ^^^^^^

  shareWith: permit

    advanced: [
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, options, callback)->

      { delegate } = client.connection
      { target, user, owner } = options
      user ?= yes

      # Owners cannot unassign them from a credential
      # Only another owner can unassign any other owner
      if delegate.profile.nickname is target
        return callback null

      setPermissionFor = (target, callback)=>

        Relationship.remove {
          targetId : @getId()
          sourceId : target.getId()
        }, (err)=>

          if user
            as = if owner then 'owner' else 'user'
            target.addProvisioner this, { as }, (err)-> callback err
          else
            callback err

      JName.fetchModels target, (err, result)=>

        if err or not result
          return callback new KodingError "Target not found."

        { models } = result
        [ target ] = models

        if target instanceof JUser
          target.fetchOwnAccount (err, account)=>
            if err or not account
              return callback new KodingError "Failed to fetch account."
            setPermissionFor account, callback

        else if target instanceof JGroup
          setPermissionFor target, callback

        else
          callback new KodingError "Target does not support provisioners."


  delete: permit 'delete provisioner',

    success: (client, callback)->

      { delegate } = client.connection

      Relationship.one
        targetId : @getId()
        sourceId : delegate.getId()
      , (err, rel)->

        return callback err   if err?
        return callback null  unless rel?
        rel.remove callback


  update$: permit

    advanced: [
      { permission: 'update provisioner', validateWith: Validators.own }
    ]

    success: (client, options, callback)->

      {content, label} = options

      if content?
        [err, content] = checkContent type, content
        if err? then return callback err

      unless content or label
        return callback new KodingError "Nothing to update"

      fieldsToUpdate =
        label             : label ? @label
        'meta.modifiedAt' : new Date

      fieldsToUpdate.content = content  if content?

      @update $set : fieldsToUpdate, (err)->
        return callback err  if err?
        callback null
