Bongo          = require "bongo"
{Relationship} = require "jraphical"

{secure, daisy, Base} = Bongo

module.exports = class ActivityTicker extends Base
  @share()

  @set
    sharedMethods :
      static      : ["fetch"]

  relationshipNames = ["follower", "like", "member", "user"]
  constructorNames  = ["JAccount", "JApp", "JGroup", "JTag"]

  @fetch = secure (client, options = {}, callback) ->
    {connection: {delegate}} = client

    selector     =
      sourceName : "$in": constructorNames
      as         : "$in": relationshipNames
      targetName : "$in": constructorNames

    options      =
      limit      : options.limit or 20
      skip       : options.skip  or 0
      sort       : timestamp  : -1

    Relationship.some selector, options, (err, relationships) ->
      buckets = []
      return  callback err, buckets  if err
      daisy queue = relationships.map (relationship) ->
        ->
          relationship.fetchTeaser ->
            {source, target, as} = relationship
            buckets.push {source, target, as}
            queue.next()

      queue.push ->
        callback null, buckets
