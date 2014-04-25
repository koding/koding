jraphical      = require 'jraphical'
KodingError    = require '../../error'
module.exports = class JProxyRestriction extends jraphical.Module

  {secure, signature, ObjectId} = require 'bongo'
  JDomain      = require "../domain"
  JProxyFilter = require "./index"

  @share()

  @set
    indexes       :
      domainName  : 'unique'
    schema        :
      domainName  : String
      filters     : [ObjectId]
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
      instance    : {}

  validate = (client, data, callback) ->
    {domainName, filterId} = data
    {delegate} = client.connection
    {nickname} = delegate.profile

    if not domainName and not filterId
      return callback new KodingError { message: "Missing arguments" }

    JDomain.fetchDomains client, (err, domains) ->
      userDomains = (domain.domain for domain in domains)
      if userDomains.indexOf(domainName) is -1
        return callback new KodingError { message: "Access Denied" }

      JProxyFilter.fetch client, { _id: filterId }, (err, filter) ->
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
        restriction = new JProxyRestriction { domainName, filters: [filterId] }
        restriction.save (err) ->
          return callback err, null  if err
          callback null, restriction
      else
        restriction.update { $addToSet: { filters: filterId } }, (err) ->
          callback err, restriction

