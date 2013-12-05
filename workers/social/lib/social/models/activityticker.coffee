Bongo          = require "bongo"
{Relationship} = require "jraphical"

{secure, daisy, Base} = Bongo

module.exports = class ActivityTicker extends Base
  @share()

  @set
    sharedMethods :
      static      : ["fetch"]

  relationshipNames = ["follower", "like", "member", "user"]
  constructorNames  = ["JAccount", "JApp", "JGroup", "JTag", "JStatusUpdate"]

  JAccount = require './account'

  decorateEvents = (relationship, callback) ->
    {source, target, as, timestamp} = relationship

    if as is "like"
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
    else
      callback null, {source, target, as, timestamp}

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
