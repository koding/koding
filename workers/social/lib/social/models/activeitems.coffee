Bongo          = require "bongo"
{Relationship} = require "jraphical"
_              = require "underscore"

JAccount       = require "./account"
JTag           = require "./tag"
Cache          = require "../cache/main"

{secure, daisy, Base, signature} = Bongo

module.exports = class ActiveItems extends Base
  @share()

  @set
    sharedMethods   :
      static        :
        fetchTopics : [
          (signature Function)
          (signature Object, Function)
        ]
        fetchUsers  : [
          (signature Function)
          (signature Object, Function)
        ]

  nameMapping =
    user    :
      klass : JAccount
      as    : ["creator", "follower"]
    topic   :
      klass : JTag
      as    : ["developer", "follower", "post"]
      select: status : $nin : ["deleted", "synonym"]

  # Returns topics in following order:
  #   * Active topics in the last day
  #   * Random topics
  @fetchTopics = secure (client, options, callback)->
    # [callback, options] = [options, callback]  unless callback
    # options.fallbackFn = @fetchRandomTopics
    # cacheId            = "#{options.group}-activeItems.fetchTopics"
    # Cache.fetch cacheId, (@fetchItems.bind this), options, callback

    options.name  = "topic"
    options.group = client.context.group
    @fetchRandomTopics callback, options

  # Returns users in following order:
  #   * Client's followers who are online
  #   * Active users in the last day
  #   * Random users
  @fetchUsers = secure (client, options, callback)->
    # [callback, options] = [options, callback]  unless callback
    # options.client      = client
    # options.group       = client.context.group
    # options.fallbackFn  = @fetchRandomUsers

    # Cache.fetch "activeItems.fetchUsers", (@_fetchUsers.bind this), options, callback

    @fetchRandomUsers callback

  @fetchRandomUsers = (callback)->
    JAccount.some {"profile.username":{"$not":/guest-/}}, {limit:10}, callback

  @fetchRandomTopics = (callback, options)->
    group = options.group or "koding"
    {select: selector} = nameMapping.topic
    selector.group = group
    JTag.some selector, {limit:10}, callback

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
        members = onlineMembers.concat activeMembers
        callback null, members

  # General method that returns popular items in the last day. If none
  # exists, it returns random items.
  #
  # Popularity is determined by number of entries in 'relationships'
  # collection that match the criteria passed to it.
  @fetchItems = (options, callback) ->
    [callback, options] = [options, callback]  unless callback
    {name, nin} = options
    mapping     = nameMapping[name]
    {klass, as, select} = mapping

    greater = (new Date(Date.now() - 1000*60*60*24))

    matcher     = {
      sourceName : klass.name
      as         : $in  : as
      timestamp  : $gte : greater
      targetName : $ne : "CFolloweeBucketActivity"
    }

    matcher.sourceId = $nin : nin  if nin

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
            if not err and instance
              instances.push instance
            queue.next()

      queue.push ->
        # If there are not enough popular results, we return random items.
        missing = 10 - instances.length
        if missing > 0
          existingIds = instances.map (i) -> i._id
          existingIds = nin.concat existingIds  if nin

          selector = {}
          selector = select if select
          selector.sourceId = {$nin : existingIds}
          klass.some selector, {limit:missing}, (err, randomInstances)->
            if not err and randomInstances
              instances = instances.concat randomInstances
            queue.next()
        else
          queue.next()

      queue.push ->
        instances = _.uniq instances, (i)-> i._id
        callback null, instances
