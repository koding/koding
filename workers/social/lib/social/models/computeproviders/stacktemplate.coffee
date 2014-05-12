
jraphical       = require 'jraphical'
JCredentialData = require './credentialdata'
JName           = require '../name'
JUser           = require '../user'
JGroup          = require '../group'

# TODO Credential relations ~g

module.exports = class JStackTemplate extends jraphical.Module

  KodingError        = require '../../error'

  {Inflector, secure, ObjectId, signature, daisy} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require '../group/permissionset'
  Validators         = require '../group/validators'

  @trait __dirname, '../../traits/protected'

  @share()

  @set

    softDelete        : yes

    permissions       :

      'create stack template'     : ['member']
      'list stack templates'      : ['member']

      'delete own stack template' : ['member']
      'update own stack template' : ['member']

      'delete stack template'     : []
      'update stack template'     : []

    sharedMethods     :

      static          :
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

    schema            :

      rules           : [ Object ]
      domains         : [ Object ]
      machines        : [ Object ]
      extras          : [ Object ]

      title           :
        type          : String
        required      : yes

      description     : String
      config          : Object

      accessLevel     :
        type          : String
        enum          : ["Wrong level specified!",
          ["private", "group", "public"]
        ]
        default       : "private"

      originId        :
        type          : ObjectId
        required      : yes

      meta            : require 'bongo/bundles/meta'

      group           : String


  @create = permit 'create stack template',

    success: (client, data, callback)->

      { delegate } = client.connection
      { profile:{nickname} } = delegate

      { title, description, config } = data
      return callback new KodingError "Title required."  unless title

      template = new JStackTemplate {
        title, description, config
        rules         : data.rules       ? []
        domains       : data.domains     ? []
        machines      : data.machines    ? []
        extras        : data.extras      ? []
        accessLevel   : data.accessLevel ? "private"
        group         : client.context.group
        originId      : delegate.getId()
      }

      template.save (err)->
        if err
          callback new KodingError "Failed to save stack template", err
        else
          callback null, template


  @some$: permit 'list stack templates',

    success: (client, selector, options, callback)->

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

      @some selector, options, (err, templates)->
        callback err, templates


  delete: permit

    advanced: [
      { permission: 'delete own stack template', validateWith: Validators.own }
      { permission: 'delete stack template' }
    ]

    success: (client, callback)-> @remove callback


  setAccess: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, accessLevel, callback)->

      @update $set: { accessLevel }, callback


  update$: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, data, callback)->

      delete data.originId
      delete data.group

      @update $set: data, (err)-> callback err
