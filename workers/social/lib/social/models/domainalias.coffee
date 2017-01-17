{ Module } = require 'jraphical'
KONFIG     = require 'koding-config-manager'

module.exports = class JDomainAlias extends Module

  KodingError  = require '../error'

  { ObjectId, signature } = require 'bongo'
  { permit } = require './group/permissionset'

  @trait __dirname, '../traits/protected'

  @share()

  @set

    softDelete        : no

    permissions       :
      'list domains'  : ['member']

    sharedMethods     :

      static          :
        one           :
          (signature Object, Function)
        some          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]

    sharedEvents      :
      static          : []
      instance        : []

    indexes           :
      domain          : 'unique'
      machineId       : 'sparse'
      originId        : 'sparse'

    schema            :

      domain          : String

      machineId       : ObjectId
      originId        : ObjectId

      createdAt       :
        type          : Date
        default       : -> new Date

  @one$ = permit 'list domains',
    success : (client, selector, callback) ->

      { delegate }      = client.connection
      selector         ?= {}
      selector.originId = delegate.getId()

      JDomainAlias.one selector, (err, domain) -> callback err, domain


  @some$ = permit 'list domains',
    success : (client, selector, options, callback) ->

      [callback, options] = [options, callback]  unless callback

      { delegate } = client.connection

      selector ?= {}
      selector.originId = delegate._id

      options      ?= {}
      options.limit = 20

      JDomainAlias.some selector, options, (err, domains) ->
        callback err, domains

  @ensureTopDomainExistence = (account, machineId, callback) ->

    { nickname } = account.profile
    topDomain  = "#{nickname}.#{KONFIG.userSitesDomain}"

    JDomainAlias.one
      originId : account._id
      domain   : topDomain
    , (err, domain) ->
      return callback err  if err?

      if domain?

        # If we decide to update existing top domain to route
        # new machine, we can use following
        # domain.update $set : { machineId }, (err) -> callback err

        callback null

      else

        domain = new JDomainAlias {
          machineId
          domain   : topDomain
          originId : account._id
        }

        domain.save (err) -> callback err
