jraphical      = require 'jraphical'
KodingError    = require '../../error'
module.exports = class JProxyRestriction extends jraphical.Module

  {secure, signature, ObjectId} = require 'bongo'
  JProposedDomain = require "../domain"
  JProxyFilter = require "./index"

  @share()

  @set
    indexes       :
      domainName  : 'unique'
    schema        :
      domainName  : String
      filters     : [ObjectId]
      owner       : ObjectId
      createdAt   :
        type      : Date
        default   : -> new Date
      modifiedAt  :
        type      : Date
        default   : -> new Date
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static      :
        create    :
          (signature Object, Function)
        remove    :
          (signature Object, Function)
        some      :
          (signature Object, Object, Function)
        clear     :
          (signature String, Function)
      instance    : {}

  validate = (client, data, callback) ->
    {domainName, filterId} = data
    {delegate} = client.connection
    {nickname} = delegate.profile

    if not domainName and not filterId
      return callback new KodingError { message: "Missing arguments" }

    JProposedDomain.fetchDomains client, (err, domains) ->
      userDomains = (domain.domain for domain in domains)
      if userDomains.indexOf(domainName) is -1
        return callback new KodingError { message: "Access Denied" }

      JProxyFilter.some { _id: filterId }, {}, (err, filter) ->
        unless filter.length
          return callback new KodingError { message: "Access Denied" }

        JProxyRestriction.one { domainName }, {}, (err, restriction) ->
          if err
            return callback new KodingError { message: "Couldn't create restriction." }

          callback null, restriction


  @create: secure (client, data, callback) ->
    {domainName, filterId} = data
    {delegate} = client.connection
    {nickname} = delegate.profile

    validate client, data, (err, restriction) ->
      return callback err  if err

      filterId = ObjectId filterId
      if not restriction
        data = { domainName, filters: [filterId], owner: delegate.getId() }
        restriction = new JProxyRestriction data
        restriction.save (err) ->
          return callback err, null  if err
          callback null, restriction
      else
        restriction.update { $addToSet: { filters: filterId } }, (err) ->
          callback err, restriction

  @remove: secure (client, data, callback) ->
    {domainName, filterId} = data
    {delegate} = client.connection
    {nickname} = delegate.profile
    filterId   = ObjectId filterId

    validate client, data, (err, restriction) ->
      restriction.update { $pullAll: { filters: [filterId] } }, (err) ->
        callback err, restriction

  @some$: secure (client, query, options, callback) ->
    query.owner = client.connection.delegate.getId()

    JProxyRestriction.some query, {}, (err, restrictions) ->
      return callback err, null  if err
      callback null, restrictions

  # When user create a firewall rule in environments, we create a JProxyFilter
  # document. When user wants to bind that rule to a domain we create a new
  # JProxyRestriction document. This document is unique for domain.
  # Inside JProxyRestriction there is a filters array that holds JProxtFilter ids.
  # This method will remove JProxyFilter id references inside JProxyRestictions.
  # Also see the comment in EnvrionmentRuleItem::confirmDestroy.
  @clear: secure (client, filterId, callback) ->
    selector    =
      filters   :
        $in     : [filterId]

    operation   =
      $pullAll  :
        filters : [filterId]

    JProxyRestriction.update selector, operation, { multi: true }, (err) ->
      callback err
