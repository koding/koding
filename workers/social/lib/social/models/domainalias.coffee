{ argv }  = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
jraphical = require 'jraphical'

module.exports = class JDomainAlias extends jraphical.Module

  KodingError  = require '../error'

  {ObjectId, signature} = require 'bongo'
  {permit} = require './group/permissionset'

  @trait __dirname, '../traits/protected'

  @share()

  @set

    softDelete        : no

    permissions       :
     'list domains'   : ['member']

    sharedMethods     :

      static          :
        one           :
          (signature Object, Function)
        some          :
          (signature Object, Object, Function)

    sharedEvents      :
      static          : []
      instance        : []

    indexes           :
      domain          : 'unique'
      machine         : 'sparse'

    schema            :

      domain          :
        type          : String
        required      : yes
        set           : (value)-> value.toLowerCase()

      machineId       : ObjectId
      originId        : ObjectId

      meta            : require "bongo/bundles/meta"



  @one$ = permit 'list domains',
    success : (client, selector, callback)->

      { delegate }      = client.connection
      selector         ?= {}
      selector.originId = delegate.getId()

      JDomainAlias.one selector, (err, domain)-> callback err, domain


  @some$ = permit 'list domains',
    success : (client, selector, options, callback)->

      { delegate }      = client.connection
      selector         ?= {}
      selector.originId = delegate.getId()
      options          ?= {}
      options.limit     = Math.min 10, (options.limit ? 10)

      JDomainAlias.some selector, options, (err, domains)->
        callback err, domains

