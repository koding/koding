Bongo          = require "bongo"
{Relationship} = require "jraphical"

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'

module.exports = class ActivityTicker extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetch     : [
          (signature Function)
          (signature Object, Function)
        ]

  JAccount = require './account'

  decorateEvents = (relationship, callback) ->
    {source, target, as, timestamp} = relationship

    return callback null  if not source or not target

    if as is "like"
      decorateLikeEvent relationship, callback
    else if as is "reply"
      decorateCommentEvent relationship, callback
    else if as is "author"
      decorateStatusUpdateEvent relationship, callback
    else
      callback null, {source, target, as, timestamp}

  decorateStatusUpdateEvent = (relationship, callback) ->
    {source, target, as, timestamp} = relationship
    source.fetchTags (err, tags) ->
      return callback err if err
      source.tags = tags
      callback null, {source, target, as, timestamp}

  decorateLikeEvent = (relationship, callback) ->
    {source, target, as, timestamp} = relationship
    # there is a flipped relationship between JAccount and JNewStatusUpdate
    # source is status update
    # target is account, we should correct it here
    # and also we should add the origin account here
    JAccount.one {"_id": source.originId}, (err, targetAccount)->
      return callback err if err

      kallback = ->
        modifiedEvent =
          source    : target
          target    : targetAccount
          subject   : source
          as        : as
          timestamp : timestamp

        callback null, modifiedEvent

      if source.bongo_.constructorName is "JNewStatusUpdate"
        source.fetchTags (err, tags) ->
          return callback err if err
          source.tags = tags
          do kallback
      else
        do kallback

  @_fetch = (requestOptions = {}, callback)->
    {options, client} = requestOptions
    groupSlug         = client.context.group
    JGroup            = require './group'
    from              = options.from or +(new Date())

    JGroup.canReadGroupActivity client, (err, hasPermission)->
      return callback new Error "Not allowed to open this group"  if err or not hasPermission

      relSelector =
        timestamp : {"$lt" : new Date(from)}
        data      :
          group   : groupSlug
        as        :
          $ne     : "commenter"

      relOptions  =    # do not fetch more than 15 at once
        limit     : 5  # Math.min options.limit ? 15, 15
        sort      : timestamp : -1

      Relationship.some relSelector, relOptions, (err, relationships) ->
        buckets = []
        return  callback err, buckets  if err
        queue = relationships.map (relationship) ->
          ->
            relationship.fetchTeaser ->
              decorateEvents relationship, (err, decoratedEvent)=>
                buckets.push decoratedEvent  if decoratedEvent
                queue.next()

        queue.push ->
          callback null, buckets
          queue.next()

        daisy queue


  @fetch = secure (client, options, callback) ->
    [callback, options] = [options, callback]  unless callback
    # TODO - add group security here
    requestOptions = { client, options }
    {group}        = client.context
    if options.from or options.filters
      @_fetch requestOptions, callback
    else
      Cache    = require '../cache/main'
      cacheKey = "#{group}-activityticker"
      Cache.fetch cacheKey, @_fetch, requestOptions, (err, data)=>
        # if data is not set, or it is empty
        # fetch from db
        if err or not data or Object.keys(data).length is 0
          @_fetch requestOptions, callback
        else
          callback err, data
