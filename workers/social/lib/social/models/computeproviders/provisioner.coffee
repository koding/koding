
jraphical   = require 'jraphical'
crypto      = require 'crypto'

JName       = require '../name'
JUser       = require '../user'
JGroup      = require '../group'

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

      'create provisioner'     : ['member']
      'list provisioners'      : ['member']

      'update own provisioner' : ['member']
      'delete own provisioner' : ['member']

      'update provisioner'     : []
      'delete provisioner'     : []

    sharedMethods     :
      static          :
        one           :
          (signature Object, Function)
        create        :
          (signature Object, Function)
        some          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
      instance        :
        delete        :
          (signature Function)
        setAccess     :
          (signature String, Function)
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

      contentSum      : String

      content         :
        type          : Object
        default       : -> { }

      accessLevel     :
        type          : String
        enum          : ["Wrong access level specified!",
          ["private", "group", "public"]
        ]
        default       : "private"

      originId        :
        type          : ObjectId
        required      : yes

      meta            : require 'bongo/bundles/meta'


  checkContent = (type, content)->

    contentSum = "%SUM%"

    if not type?
      err = "Type missing."
    else if not content?
      err = "Content missing."
    else
      switch type
        when "shell"
          unless content.script?
            err = "Type shell requires a `script`"
          else

            contentSum = crypto.createHash 'sha1'
              .update "#{content.script}"
              .digest 'hex'

            content = { script: content.script }

        else
          err = "Type is not supported for now."

    err = new KodingError err  if err?
    return [err, content, contentSum]


  checkSlug = (slug, callback)->

    JProvisioner.count { slug }, (err, res)->
      return callback err  if err?
      if not res? or res > 0
      then callback new KodingError \
        "Slug `#{slug}` in use, provide different one"
      else callback null


  checkData = (delegate, data, callback)->

    {type, content, slug, label, accessLevel} = data

    [err, content, contentSum] = checkContent type, content
    if err? then return callback err

    accessLevel ?= 'private'

    slug ?= (require 'hat') 32
    slug  = "#{delegate.profile.nickname}/#{slug}"

    checkSlug slug, (err)->
      return callback err  if err?
      callback null, {
        type, slug, label, content, contentSum
        originId : delegate.getId(), accessLevel
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


  someHelper = (client, selector, options, callback)->

    [options, callback] = [callback, options]  unless callback
    options ?= {}

    { delegate } = client.connection

    unless typeof selector is 'object'
      return callback new KodingError "Invalid query"

    selector.$and ?= []
    selector.$and.push
      $or : [
        { originId      : delegate.getId() }
        { accessLevel   : 'public' }
        {
          $and          : [
            accessLevel : 'group'
            group       : client.context.group
          ]
        }
      ]

    JProvisioner.some selector, options, (err, templates)->
      callback err, templates


  @some$ = permit 'list provisioners', success: someHelper

  @one$  = permit 'list provisioners',

    success: (client, selector, callback)->

      someHelper client, selector, limit: 1, (err, provisioners)->
        callback err, (provisioners[0]  if provisioners?)


  delete: permit

    advanced: [
      { permission: 'delete own provisioner', validateWith: Validators.own }
      # { permission: 'delete provisioner' }
    ]

    success: (client, callback)-> @remove callback


  setAccess: permit

    advanced: [
      { permission: 'update own provisioner', validateWith: Validators.own }
      # { permission: 'update provisioner' }
    ]

    success: (client, accessLevel, callback)->

      @update $set: { accessLevel }, callback


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
