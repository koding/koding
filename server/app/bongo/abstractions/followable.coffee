class Followable extends jraphical.Module

  {dash} = bongo
  {Relationship,Module} = jraphical

  @schema =
    counts        :
      followers   :
        type      : Number
        default   : 0
      following   :
        type      : Number
        default   : 0

  count: bongo.secure (client, filter, callback)->
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

  @someWithRelationship = bongo.secure (client, selector, options, callback)->
    @some selector, options, (err, followables)=>
      if err then callback err else @markFollowing client, followables, callback

  @markFollowing = bongo.secure (client, followables, callback)->
    Relationship.all
      targetId  : client.connection.delegate.getId()
      as        : 'follower'
    , (err, relationships)->
      for followable in followables
        followable.followee = no
        for relationship, index in relationships
          if followable.getId().equals relationship.sourceId
            followable.followee = yes
            relationships.splice index,1
            break
      callback err, followables

  follow: bongo.secure (client, options, callback)->
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
          console.log 'Kount', count
          if err
            callback err
          else
            Module::update.call @, $set: 'counts.followers': count, (err)->
              if err then log err
            # callback err, count
            @emit 'FollowCountChanged'
              followerCount   : @getAt('counts.followers')
              followingCount  : @getAt('counts.following')
              newFollower     : follower

            follower.updateFollowingCount()
            Relationship.one {sourceId, targetId, as:'follower'}, (err, relationship)=>
              if err
                callback err
              else
                emitActivity = options.emitActivity ? @constructor.emitFollowingActivities ? no
                if emitActivity
                  CBucket.addActivities relationship, @, follower, (err)->
                    if err
                      # console.log "An Error occured: ", err
                      callback err
                    else
                      callback null, count
                else callback null, count

  unfollow: bongo.secure (client,callback)->
    follower = client.connection.delegate
    @removeFollower follower, respondWithCount : yes, (err, docs, count)=>
      if err
        console.log err
      else
        bongo.Model::update.call @, $set: 'counts.followers': count, (err)->
          throw err if err
        callback err, count
        @emit 'FollowCountChanged'
          followerCount   : @getAt('counts.followers')
          followingCount  : @getAt('counts.following')
          oldFollower     : follower
        follower.updateFollowingCount()

  fetchFollowing: (query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    # log query, page
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JAccount.all _id: $in: ids, (err, accounts)->
          callback err, accounts

  fetchFollowers: (query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JAccount.all _id: $in: ids, (err, accounts)->
          callback err, accounts

  fetchFollowersWithRelationship: bongo.secure (client, query, page, callback)->
    @fetchFollowers query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback

  fetchFollowingWithRelationship: bongo.secure (client, query, page, callback)->
    @fetchFollowing query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback

  fetchFollowedTopics: bongo.secure (client, query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JTag.all _id: $in: ids, (err, accounts)->
          callback err, accounts

  updateFollowingCount: ()->
    Relationship.count targetId:@_id, as:'follower', (error, count)=>
      bongo.Model::update.call @, $set: 'counts.following': count, (err)->
        throw err if err
      @emit 'FollowCountChanged'
        followerCount   : @getAt('counts.followers')
        followingCount  : @getAt('counts.following')
