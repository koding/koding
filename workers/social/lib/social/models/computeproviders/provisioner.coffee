
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

      originId        :
        type          : ObjectId
        required      : yes

      meta            : require 'bongo/bundles/meta'

  @getName = -> 'JProvisioner'

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


  checkData = (delegate, data, callback)->

    {type, content, slug, label} = data

    [err, content] = checkContent type, content
    if err? then return callback err

    slug ?= (require 'hat') 32
    slug  = "#{delegate.profile.nickname}/#{slug}"

    JProvisioner.count { slug }, (err, res)->
      return callback err  if err?
      if not res? or res > 0
        callback new KodingError "Slug `#{slug}` in use, provide different one"
      else
        callback null, {
          type, slug, label, content
          originId : delegate.getId()
        }


  @create = permit 'create provisioner',

    success: (client, data, callback)->

      {delegate} = client.connection

      checkData delegate, data, (err, data)->

        if err? then return callback err

        provisioner = new JProvisioner data
        provisioner.save (err)->

          return callback err  if err
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


  @one$ = permit 'list provisioners',

    success: (client, slug, callback)->

      @fetchBySlug client, slug, callback


  @some$ = permit 'list provisioners', success: JCredential.someHelper


  fetchUsers: JCredential::fetchUsers


  setPermissionFor: (target, {user, owner}, callback)->

    Relationship.remove
      targetId : @getId()
      sourceId : target.getId()
    , (err)=>

      if user
        as = if owner then 'owner' else 'user'
        target.addProvisioner this, { as }, (err)-> callback err
      else
        callback err

  # .share can be used like this:
  #
  # JProvisionerInstance.share { user: yes, owner: no, target: "gokmen"}, cb
  #                                       group or user slug -> ^^^^^^

  shareWith$: permit

    advanced: [
      { permission: 'update provisioner', validateWith: Validators.own }
    ]

    success: JCredential::shareWith


  delete: permit 'delete provisioner',

    success: (client, callback)->

      { delegate } = client.connection

      Relationship.one
        targetId : @getId()
        sourceId : delegate.getId()
      , (err, rel)=>

        return callback err   if err?
        return callback null  unless rel?

        if rel.data.as is 'owner'
          @remove callback
        else
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
