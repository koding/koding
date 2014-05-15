jraphical = require 'jraphical'
KodingError = require '../error.coffee'
CBucket = require '../models/bucket'

module.exports = class Followable

  {Model, dash, secure, ObjectRef} = require 'bongo'
  {Relationship, Module} = jraphical
  {extend} = require 'underscore'

  @schema =
    counts        :
      followers   :
        type      : Number
        default   : 0
      following   :
        type      : Number
        default   : 0

  count: secure (client, filter, callback)->
    unless @equals client.connection.delegate
      callback new KodingError 'Access denied'
    else switch filter
      when 'followers'
        Relationship.count
          sourceId  : @getId()
          as        : 'follower'
        , callback
      when 'following'
        Relationship.count
          targetId  : @getId()
          as        : 'follower'
        , callback
      else
        @constructor.count {}, callback

  @fetchMyFollowees = secure (client, ids, callback)->
    [callback, ids] = [ids, callback]  unless callback
    return  unless callback
    return callback null  unless ids
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'

    Relationship.someData {
      sourceId  :
        $in     : ids
      targetId  : client.connection.delegate.getId()
      as        : 'follower'
    }, {sourceId:1}, (err, cursor)->
      if err then callback err
      else
        cursor.toArray (err, docs)->
          if err
            callback err
          else
            callback null, (doc.sourceId for doc in docs)

  @cursorWithRelationship =do->
    wrapNextModelMethod = (nextObject, delegate, callback)->
      nextObject (err, model)->
        if err then callback err
        else unless model?
          callback err, null
        else
          Relationship.count {
            targetId  : delegate.getId()
            sourceId  : model.getId()
            as        : 'follower'
          }, (err, count)->
            if err then callback err
            else
              model.followee = count > 0
              callback null, model

    cursorWithRelationship = secure (client, selector, options, callback)->
      {delegate} = client.connection
      @cursor selector, options, (err, cursor)->
        if err then callback err
        else
          nextModel = wrapNextModelMethod.bind null, cursor.nextModel, delegate
          cursor.nextModel = nextModel
          callback null, cursor

  @someWithRelationship = secure (client, selector, options, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    @some selector, options, (err, followables)=>
      if err then callback err else @markFollowing client, followables, callback

  @markFollowing = secure (client, followables, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    Relationship.all
      sourceId  :
        $in     : (followable.getId() for followable in followables)
      targetId  : client.connection.delegate.getId()
      as        : 'follower'
    , (err, relationships)->
      followables.forEach (followable)->
        followable.followee = no
        relationships.forEach (relationship)->
          if relationship.sourceId.equals followable.getId()
            followable.followee = yes
      callback err, followables

  follow: secure (client, options, callback)->
    JAccount = require '../models/account'
    JGroup   = require '../models/group'
    Inflector = require 'inflector'

    [callback, options] = [options, callback] unless callback
    options or= {}
    follower = client.connection.delegate

    if follower.type is 'unregistered'
      return callback new KodingError 'Access denied'

    unless follower instanceof JAccount
      return callback new KodingError 'Access denied'

    if @equals follower
      return callback(
        new KodingError("Can't follow yourself")
        @getAt('counts.followers')
      )

    sourceId = @getId()
    targetId = follower.getId()
    {group}  = client.context

    Relationship.count {
      sourceId, targetId, as:'follower'
    }, (err, count)=>
      if err
        callback err
      else if count > 0
        callback null, count
      else
        options            =
          respondWithCount : yes
          data             : {group}

        @addFollower follower, options, (err, docs, count)=>
          if err
            callback err
          else
            Module::update.call @, $set: 'counts.followers': count, (err)->
              if err then log err
            action = "follow"
            @emit 'FollowCountChanged',
              followerCount   : @getAt 'counts.followers'
              followingCount  : @getAt 'counts.following'
              follower        : follower
              action          : action

            @constructor.emit 'FollowHappened',
              followee  : this
              follower  : follower

            @emit 'FollowHappened',
              origin    : this
              actorType : 'follower'
              follower  : ObjectRef(follower).data
              group     : group
            SocialChannel = require '../models/socialapi/channel'
            SocialChannel.followUser client, {followee: this}, (err) -> console.warn err  if err

            follower.updateFollowingCount @, action

            follower.updateMetaModifiedAt ()->

            callback err, count

            Relationship.one {sourceId, targetId, as:'follower'}, (err, relationship)=>
              if err
                callback err
              else
                emitActivity = options.emitActivity ? @constructor.emitFollowingActivities ? no
                if emitActivity
                  CBucket.addActivities relationship, @, follower, null, (err)->
                    console.log "An Error occured: #{err}" if err

  unfollow: secure (client,callback)->
    JAccount = require '../models/account'
    follower = client.connection.delegate

    if follower.type is 'unregistered'
      return callback new KodingError 'Access denied'

    @removeFollower follower, respondWithCount : yes, (err, count)=>
      if err
        console.log err
      else
        Module::update.call @, $set: 'counts.followers': count, (err)->
          throw err if err
        callback err, count
        action = "unfollow"

        @constructor.emit 'UnfollowHappened',
          followee        : this
          follower        : follower

        @emit 'FollowCountChanged',
          followerCount   : @getAt('counts.followers')
          followingCount  : @getAt('counts.following')
          follower        : follower
          action          : action

        SocialChannel = require '../models/socialapi/channel'
        SocialChannel.followUser client, {followee: this, unfollow: yes}, (err) ->
          console.warn err  if err

        follower.updateFollowingCount @, action

  fetchFollowing: (query, page, callback)->
    JAccount = require '../models/account'

    extend query,
      targetId  : @getId()
      as        : 'follower'
      sourceName: @constructor.name
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JAccount.all _id: $in: ids, (err, accounts)->
          callback err, accounts

  countFollowing: (query, callback)->
    JAccount = require '../models/account'

    extend query,
      targetId  : @getId()
      as        : 'follower'
      sourceName: @constructor.name
    Relationship.count query, (err, count)->
      callback err, count

  getQueryWithGroupMembers = (client, query, orientation, callback)->
    {group} = client.context
    if group is 'koding'
      return callback null, query

    JGroup = require '../models/group'
    JGroup.one slug:group, (err, groupModel)->
      return callback err if err
      selector =
        sourceId   : groupModel._id
        sourceName : 'JGroup'
        targetName : 'JAccount'
        as         : 'member'
      Relationship.some selector, {}, (err, rels)->
        return callback err if err
        query["#{orientation}Id"] = $in: (rel.targetId for rel in rels)
        callback null, query

  fetchFollowersWithRelationship: secure (client, query, page, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    getQueryWithGroupMembers client, query, 'target', (err, filteredQuery)=>
      return callback err if err
      @fetchFollowers filteredQuery, page, (err, accounts)->
        if err then callback err else JAccount.markFollowing client, accounts, callback

  countFollowersWithRelationship: secure (client, query, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    getQueryWithGroupMembers client, query, 'target', (err, filteredQuery)=>
      return callback err if err
      @countFollowers filteredQuery, (err, count)->
        if err then callback err else callback null, count

  fetchFollowingWithRelationship: secure (client, query, page, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    getQueryWithGroupMembers client, query, 'source', (err, filteredQuery)=>
      return callback err if err
      @fetchFollowing query, page, (err, accounts)->
        if err then callback err else JAccount.markFollowing client, accounts, callback

  countFollowingWithRelationship: secure (client, query, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    getQueryWithGroupMembers client, query, 'source', (err, filteredQuery)=>
      return callback err if err
      @countFollowing query, (err, count)->
        if err then callback err else callback null, count

  fetchFollowedTopics: secure (client, query, page, callback)->
    JAccount = require '../models/account'
    unless client.connection.delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    extend query,
      targetId  : @getId()
      as        : 'follower'
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        {group} = client.context
        ids = (rel.sourceId for rel in docs)
        selector = _id: $in: ids
        selector.group = group if group isnt 'koding'

        JTag = require '../models/tag'
        JTag.all _id: $in: ids, (err, accounts)->
          callback err, accounts

  isFollowing: secure (client, sourceId, sourceName, callback) ->
    unless @equals client.connection.delegate
      callback new KodingError 'Access denied'
    else
      selector =
        targetId: @getId()
        as: 'follower'
        sourceId: sourceId
        sourceName: sourceName
      Relationship.one selector, (err, rel) ->
        if rel? and not err?
          callback null, yes
        else
          callback null, no

  updateFollowingCount: (followee, action)->
    if @constructor.name is 'JAccount'
      @updateCounts()
    else
      Relationship.count targetId:@_id, as:'follower', (error, count)=>
        Model::update.call @, $set: 'counts.following': count, (err)->
          throw err if err
        @emit 'FollowCountChanged',
          followerCount   : @getAt('counts.followers')
          followingCount  : @getAt('counts.following')
          followee        : followee
          action          : action
