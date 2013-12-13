Bongo          = require "bongo"
{Relationship} = require "jraphical"

{secure, daisy, dash, signature, Base} = Bongo

module.exports = class ActivityTicker extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetch     : [
          (signature Function)
          (signature Object, Function)
        ]

  relationshipNames = ["follower", "like", "member", "user", "reply", "author"]
  constructorNames  = ["JAccount", "JNewApp", "JGroup", "JTag", "JNewStatusUpdate", "JComment"]

  JAccount = require './account'

  filterSources = (filters) =>
    constructorNames  = ["JAccount", "JNewApp", "JGroup", "JTag", "JNewStatusUpdate", "JComment"]

    relationshipMap =
      "follower" : ["JTag"]
      "like"     : ["JAccount", "JNewStatusUpdate"]
      "member"   : ["JGroup"]
      "user"     : ["JApp"]

    sources = []
    for filter in filters
      sources.concat relationshipMap[filter]

    if sources.length is 0
      return constructorNames
    return sources

  filterTargets = (filters) ->
    constructorNames = ["follower", "like", "member", "user"]
    targets = []
    # The only possible options are either returning only "JAccount" or
    # returning whole constructorNames. I left this function for future-cases.
    for filter in filters
      if filter in constructorNames
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
    {source, target, as, timestamp} = relationship
    modifiedEvent =
      as        : as
      subject   : source
      object    : target
      timestamp : timestamp

    queue = [
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

      modifiedEvent =
        source    : target
        target    : targetAccount
        subject   : source
        as        : as
        timestamp : timestamp

      callback null, modifiedEvent


  @fetch = secure (client, options, callback) ->
    [callback, options] = [options, callback]  unless callback
    {connection: {delegate}} = client

    sources = constructorNames
    as      = relationshipNames
    targets = constructorNames

    filters = []
    if options?.filters
      for filter in options.filters  when filter in relationshipNames
        filters.push filter

    if filters.length > 0
      sources = filterSources options.filters
      as      = options.filters
      targets = filterTargets options.filters


    from = options.from or +(new Date())
    selector     =
      sourceName : "$in": sources
      as         : "$in": as
      targetName : "$in": targets
      timestamp : {"$lt" : new Date(from)}

    options      =
      # do not fetch more than 15 at once
      limit      : 10 # Math.min options.limit ? 15, 15
      sort       : timestamp  : -1

    Relationship.some selector, options, (err, relationships) ->
      buckets = []
      return  callback err, buckets  if err
      daisy queue = relationships.map (relationship) ->
        ->
          relationship.fetchTeaser ->
            decorateEvents relationship, (err, decoratedEvent)=>
              buckets.push decoratedEvent  if decoratedEvent
              queue.next()

      queue.push ->
        callback null, buckets
