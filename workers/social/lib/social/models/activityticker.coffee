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

  relationshipNames = ["follower", "like", "member", "author"]
  constructorNames  = ["JAccount", "JGroup", "JTag", "JNewStatusUpdate"]

  JAccount = require './account'

  mapSourceNames = (filters)=>
    relationshipMap =
      "follower" : ["JAccount", "JTag"]
      "like"     : ["JAccount", "JNewStatusUpdate"]
      "member"   : ["JGroup"]

    sources = []
    for filter in filters
      sources.concat relationshipMap[filter]

    if sources.length is 0
      return constructorNames
    return sources

  mapTargetNames = (filters) ->
    validFilters = ["follower", "like", "member"]
    targets = []
    # The only possible options are either returning only "JAccount" or
    # returning whole constructorNames. I left this function for future-cases.
    for filter in filters
      if filter in validFilters
        targets.push "JAccount"
        return targets
    return constructorNames

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


  decorateCommentEvent = (relationship, callback) ->
    # it will be decorated as
    # source is JAccount          -- doer
    # target is JAccount          -- owner of the status update
    # object is JComment          -- the actual comment
    # subject is JNewStatusUpdate -- post that is commented on
    {source, target, as, timestamp} = relationship
    modifiedEvent =
      as        : as
      subject   : source
      object    : target
      timestamp : timestamp

    # rewrite this part without dash ~ C.S
    queue = [
      ->
        source.fetchTags (err, tags) ->
          return callback err if err
          modifiedEvent.subject.tags = tags
          queue.fin()
      # disable for now
      # ->
      #   target.fetchTags (err, tags) ->
      #     return callback err if err
      #     modifiedEvent.object.tags = tags
      #     queue.fin()
      ->
        JAccount.one "_id": source.originId, (err, targetAccount) ->
          return callback err if err
          modifiedEvent.target = targetAccount
          queue.fin()
      ->
        JAccount.one "_id": target.originId, (err, sourceAccount) ->
          return callback err if err
          modifiedEvent.source = sourceAccount
          queue.fin()
    ]

    dash queue, -> callback null, modifiedEvent

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
    sources = constructorNames
    as      = relationshipNames
    targets = constructorNames

    filters = []
    if options.filters
      for filter in options.filters  when filter in relationshipNames
        filters.push filter

    if filters.length > 0
      sources = mapSourceNames filters
      as      = filters
      targets = mapTargetNames filters


    from = options.from or +(new Date())
    selector     =
      sourceName : "$in": sources
      as         : "$in": as
      targetName : "$in": targets
      timestamp : {"$lt" : new Date(from)}

    relOptions      =
      # do not fetch more than 15 at once
      limit      : 7 # Math.min options.limit ? 15, 15
      sort       : timestamp  : -1

    JGroup = require './group'
    JGroup.one slug:'guests', (err, group)->
      return callback err if err
      return callback new Error "Group not found" if not group
      # do not include guest group results to data set
      selector.sourceId = { "$ne" : group.getId() }

      Relationship.some selector, relOptions, (err, relationships) ->
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

    if options.from or options.filters
      @_fetch requestOptions, callback
    else
      Cache  = require '../cache/main'
      cacheKey = "activityticker"
      Cache.fetch cacheKey, @_fetch, requestOptions, (err, data)=>
        # if data is not set, or it is empty
        # fetch from db
        if err or not data or Object.keys(data).length is 0
          @_fetch requestOptions, callback
        else
          callback err, data
