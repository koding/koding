Bongo          = require "bongo"
{Relationship} = require "jraphical"

{secure, daisy, dash, Base} = Bongo

module.exports = class ActivityTicker extends Base
  @share()

  @set
    sharedMethods :
      static      : ["fetch"]

  relationshipNames = ["follower", "like", "member", "user", "reply"]
  constructorNames  = ["JAccount", "JApp", "JGroup", "JTag", "JStatusUpdate","JComment"]

  JAccount = require './account'

  decorateEvents = (relationship, callback) ->
    {source, target, as, timestamp} = relationship

    if as is "like"
      decorateLikeEvent relationship, callback
    else if as is "reply"
      decorateCommentEvent relationship, callback
    else
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
    # there is a flipped relationship between JAccount and JStatusUpdate
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


  @fetch = secure (client, options = {}, callback) ->
    {connection: {delegate}} = client

    from = options.from or +(new Date())
    selector     =
      sourceName : "$in": constructorNames
      as         : "$in": relationshipNames
      targetName : "$in": constructorNames
      timestamp : {"$lt" : new Date(from)}

    options      =
      # do not fetch more than 15 at once
      limit      : Math.min options.limit ? 15, 15
      sort       : timestamp  : -1

    Relationship.some selector, options, (err, relationships) ->
      buckets = []
      return  callback err, buckets  if err
      daisy queue = relationships.map (relationship) ->
        ->
          relationship.fetchTeaser ->
            decorateEvents relationship, (err, decoratedEvent)=>
              buckets.push decoratedEvent
              queue.next()

      queue.push ->
        callback null, buckets
