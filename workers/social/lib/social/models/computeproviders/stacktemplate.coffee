
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

      connections     : [ Object ]

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
        connections   : data.connections ? []
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

# Base StackTemplate example for koding group
###

{JStackTemplate} = KD.remote.api

JStackTemplate.create

  title       : "Koding"
  description : "Koding's default stack template for new users"

  config      :
    subdomain : ".kd.io"

  rules       : [
    {
      name    : "Allow Gokmen"
      rules   : [
          {
              type    : "ip",
              match   : "176.33.13.53",
              action  : "allow",
              enabled : yes
          }
      ]
      enabled : yes
    }
    {
      name    : "Allow Turkey"
      rules   : [
          {
              type    : "country",
              match   : "TR",
              action  : "allow",
              enabled : yes
          }
      ]
      enabled : yes
    }
  ]

  domains     : [
    { domain  : "{{profile.nickname}}{{config.subdomain}}" }
    { domain  : "digitalocean.{{profile.nickname}}{{config.subdomain}}" }
    { domain  : "aws.{{profile.nickname}}{{config.subdomain}}" }
  ]

  machines    : [
    {
      title: "Development VM", vendor: "koding", instanceType: "micro"
    }
    {
      title: "Test VM on DO", vendor: "digitalocean", instanceType: "micro",
      credential: "703484dfc34fc9b9830c43eddb2725f5", image: "ubuntu-13-10-x64",
      region: "ams1", size: "512mb"
    }
    {
      title: "AWS micro", vendor: "amazon", instanceType: "micro"
    }
  ]

  connections : [
    { rules   : 0, domains  : 0 }
    { rules   : 0, domains  : 1 }
    { rules   : 1, domains  : 0 }
    { domains : 0, machines : 0 }
    { domains : 1, machines : 1 }
    { domains : 2, machines : 2 }
  ]

, (err, template)->

  console.log err, template

###
