Bongo          = require "bongo"
{Relationship} = require "jraphical"
_              = require "underscore"

JAccount       = require "./account"
JTag           = require "./tag"
Cache          = require "../cache/main"

{secure, daisy, Base} = Bongo

module.exports = class ActiveItems extends Base
  @share()

  @set
    sharedMethods :
      static      : ["fetchTopics", "fetchUsers"]

  nameMapping =
    user    :
      klass : JAccount
      as    : ["creator", "follower"]
    topic   :
      klass : JTag
      as    : ["developer", "follower", "post"]

  # Returns topics in following order:
  #   * Active topics in the last day
  #   * Random topics
  @fetchTopics = secure (client, options={}, callback)->
    options.name       = "topic"
    options.fallbackFn = @fetchRandomTopics

    Cache.fetch "activeItems.fetchTopics", (@fetchItems.bind this), options, callback

  # Returns users in following order:
  #   * Client's followers who are online
  #   * Active users in the last day
  #   * Random users
  @fetchUsers = secure (client, options={}, callback)->
    options.client     = client
    options.fallbackFn = @fetchRandomUsers

    Cache.fetch "activeItems.fetchUsers", (@_fetchUsers.bind this), options, callback

  @fetchRandomUsers = (callback)-> JAccount.some {}, {limit:10}, callback

  @fetchRandomTopics = (callback)-> JTag.some {}, {limit:10}, callback

  @_fetchUsers = (options={}, callback)->
    {client}   = options
    {delegate} = client.connection

    delegate._fetchMyOnlineFollowingsFromGraph client, {}, (err, onlineMembers)=>
      return callback err                  if err
      return callback null, onlineMembers  if onlineMembers.length >= 10

      missing     = 10 - onlineMembers.length
      existingIds = onlineMembers.map (member)-> member._id

      @fetchItems {name: "user", count:missing, nin:existingIds}, (err, activeMembers)->
        return callback err  if err
        members = _.flatten activeMembers, onlineMembers
        callback null, members

  # General method that returns popular items in the last day. If none
  # exists, it returns random items.
  #
  # Popularity is determined by number of entries in 'relationships'
  # collection that match the criteria passed to it.
  @fetchItems = (options={}, callback) ->
    {name}      = options
    mapping     = nameMapping[name]
    {klass, as} = mapping

    greater = (new Date(Date.now() - 1000*60*60*24))

    matcher     = {
      sourceName : klass.name
      as         : $in  : as
      timestamp  : $gte : greater
    }

    matcher.sourceId = $nin : options.nin  if options.nin

    limit = options.limit or 10

    Relationship.getCollection().aggregate {$match: matcher},
      {$group:{_id:"$sourceId", total:{$sum:1}}},
      {$limit:limit},
    , (err, items)->
      return callback err  if err

      items = _.sortBy items, (item)-> item.sum
      items = items.reverse()
      items = items[0..10]

      instances = []
      daisy queue = items.map (item) ->
        ->
          klass.one _id: item._id, (err, instance)->
            instances.push instance
            queue.next()

      queue.push ->
        # If there are not enough popular results, we return random items.
        missing = 10 - instances.length
        if missing > 0
          existingIds = instances.map (i) -> i._id
          klass.some {_id: $nin : existingIds}, {limit:missing}, (err, randomInstances)->
            return callback err  if err

            # first array must contain entries or _ returns []
            instances = _.flatten randomInstances, instances
            callback null, instances
        else
          callback null, instances
