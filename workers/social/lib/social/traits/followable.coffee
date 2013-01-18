jraphical = require 'jraphical'
KodingError = require '../error.coffee'
CBucket = require '../models/bucket'

module.exports = class Followable

  {Model, dash, secure} = require 'bongo'
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
    @some selector, options, (err, followables)=>
      if err then callback err else @markFollowing client, followables, callback

  @markFollowing = secure (client, followables, callback)->
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
    [callback, options] = [options, callback] unless callback
    options or= {}
    follower = client.connection.delegate
    if @equals follower
      return callback(
        new KodingError("Can't follow yourself")
        @getAt('counts.followers')
      )

    sourceId = @getId()
    targetId = follower.getId()

    Relationship.count {
      sourceId, targetId, as:'follower'
    }, (err, count)=>
      if err
        callback err
      else if count > 0
        callback new KodingError('already following...'), count
      else
        @addFollower follower, respondWithCount : yes, (err, docs, count)=>
          if err
            callback err
          else
            Module::update.call @, $set: 'counts.followers': count, (err)->
              if err then log err
            action = "follow"
            @emit 'FollowCountChanged'
              followerCount   : @getAt('counts.followers')
              followingCount  : @getAt('counts.following')
              follower        : follower
              action          : action

            # JAccount.emit 'FollowingRelationshipChanged'
            #   follower: follower.getId()
            #   followee: @getId()
            #   action  : action

            follower.updateFollowingCount @, action

            callback err, count

            Relationship.one {sourceId, targetId, as:'follower'}, (err, relationship)=>
              if err
                callback err
              else
                emitActivity = options.emitActivity ? @constructor.emitFollowingActivities ? no
                if emitActivity
                  CBucket.addActivities relationship, @, follower, (err)->
                    if err
                      console.log "An Error occured: ", err
                      # callback err
                #     else
                #       callback null, count
                # else callback null, count

  unfollow: secure (client,callback)->
    JAccount = require '../models/account'
    follower = client.connection.delegate
    @removeFollower follower, respondWithCount : yes, (err, count)=>
      if err
        console.log err
      else
        Module::update.call @, $set: 'counts.followers': count, (err)->
          throw err if err
        callback err, count
        action = "unfollow"
        @emit 'FollowCountChanged'
          followerCount   : @getAt('counts.followers')
          followingCount  : @getAt('counts.following')
          follower        : follower
          action          : action

        # JAccount.emit 'FollowingRelationshipChanged'
        #   follower: follower.getId()
        #   followee: @getId()
        #   action  : action

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

  fetchFollowersWithRelationship: secure (client, query, page, callback)->
    JAccount = require '../models/account'
    @fetchFollowers query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback

  fetchFollowingWithRelationship: secure (client, query, page, callback)->
    JAccount = require '../models/account'
    @fetchFollowing query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback

  fetchFollowedTopics: secure (client, query, page, callback)->
    extend query,
      targetId  : @getId()
      as        : 'follower'
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
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
          callback yes
        else
          callback no

  updateFollowingCount: (followee, action)->
    if @constructor.name is 'JAccount'
      @updateCounts()
    else
      Relationship.count targetId:@_id, as:'follower', (error, count)=>
        Model::update.call @, $set: 'counts.following': count, (err)->
          throw err if err
        @emit 'FollowCountChanged'
          followerCount   : @getAt('counts.followers')
          followingCount  : @getAt('counts.following')
          followee        : followee
          action          : action
