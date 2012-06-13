class Followable extends jraphical.Module
  
  {dash} = bongo
  
  @set
    schema          :
      counts        :
        followers   :
          type      : Number
          default   : 0
        following   :
          type      : Number
          default   : 0
    relationships   :
      activity      : CActivity
  
  count: bongo.secure (client, filter, callback)->
    unless @equals client.connection.delegate
      callback new Error 'Access denied'
    else
      switch filter
        when 'followers'
          jraphical.Relationship.count sourceId : @getId(), as : 'follower', callback
        when 'following'
          jraphical.Relationship.count targetId : @getId(), as : 'follower', callback
        else
          @constructor.count {}, callback
  
  @someWithRelationship = bongo.secure (client, selector, options, callback)->
    @some selector, options, (err, followables)=>
      if err then callback err else @markFollowing client, followables, callback
  
  @markFollowing = bongo.secure (client, followables, callback)->
    jraphical.Relationship.all
      targetId : client.connection.delegate.getId()
      as : 'follower'
    , (err, relationships)->
      for followable in followables
        followable.followee = no
        for relationship, index in relationships
          if followable.getId().equals relationship.sourceId
            followable.followee = yes
            relationships.splice index,1
            break
      callback err, followables
  
  follow: bongo.secure do ->
    # @helper
    addToBucket =do ->
      # @helper
      addIt = (bucket, anchor, item, callback)->
        bucket.add item, (err)->
          if err
            callback err
          else
            console.log bucket.getId()
            jraphical.Relationship.one {
              targetId: bucket.getId()
              sourceName: bucket.constructor.name + 'Activity'
              as: 'content'
            }, (err, rel)->
              if err
                callback err
              else if rel
                konstructor = bongo.Base.constructors[rel.sourceName]
                konstructor.one _id: rel.sourceId, (err, activity)->
                  if err
                    callback err
                  else
                    anchor.assureActivity activity, (err)->
                      if err
                        callback err
                      else
                        callback null, bucket
              else
                activity = CBucketActivity.create bucket
                activity.save (err)->
                  if err
                    callback err
                  else
                    anchor.addActivity activity, (err)->
                      if err
                        callback err
                      else
                        activity.addSubject bucket, (err)->
                          if err
                            callback err
                          else
                            activity.update
                              $set          :
                                snapshot    : JSON.stringify(bucket)
                              $addToSet     :
                                snapshotIds : bucket.getId()
                            , (err)->
                              if err
                                callback err
                              else
                                callback null, bucket

      (groupName, relationship, item, anchor, callback)->
        today = $gte: new Date Date.now() - 1000*60*60*12
        followBucketConstructor = switch groupName
          when 'source' then CFolloweeBucket
          when 'target' then CFollowerBucket
        existingBucketSelector = {
          groupedBy   : groupName
          sourceName  : relationship.sourceName
          'anchor.id' : relationship[groupName+'Id']
          'meta.createdAt'   : today
        }
        followBucketConstructor.one existingBucketSelector, (err, bucket)->
          if err then callback err
          else if bucket
            addIt bucket, anchor, item, callback
          else
            bucket = new followBucketConstructor
              groupedBy         : groupName
              sourceName        : relationship.sourceName
              anchor            :
                constructorName : relationship[groupName+'Name']
                id              : relationship[groupName+'Id']
          
            bucket.save (err)->
              if err then callback err
              else addIt bucket, anchor, item, callback
              
    # @helper  
    addActivities =(relationship, source, target, callback)->
      queue = []
      fin = -> queue.fin()
      queue.push -> addToBucket 'source', relationship, target, source, fin
      queue.push -> addToBucket 'target', relationship, source, target, fin
      dash queue, callback
    
    # @implementation
    (client,callback)->
      follower = client.connection.delegate
      if @equals follower then return callback "Can't follow yourself, you egotistical maniac", @counts.followers
      @addFollower follower, returnCount : yes, (err, count)=>
        if err
          callback err
        else
          @counts.followers = count
          @save()
          # callback err, count
          @emit 'FollowCountChanged'
            followerCount   : @counts.followers
            followingCount  : @counts.following
            newFollower     : follower
        
          follower.updateFollowingCount()
        
          sourceId = @getId()
          targetId = follower.getId()
        
          jraphical.Relationship.one {sourceId, targetId, as:'follower'}, (err, relationship)=>
            if err
              callback err
            else
              addActivities relationship, @, follower, (err)->
                if err
                  callback err
                else
                  callback null, count

  unfollow: bongo.secure (client,callback)->
    follower = client.connection.delegate
    @removeFollower follower, returnCount : yes, (err, count)=>
      if err
        console.log err
      else
        bongo.Model::update.call @, $set: 'counts.followers': count, (err)->
          throw err if err
        callback err, count
        @emit 'FollowCountChanged'
          followerCount   : @counts.followers
          followingCount  : @counts.following
          oldFollower     : follower
        follower.updateFollowingCount()
  
  fetchFollowing: (query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    # log query, page
    jraphical.Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JAccount.all _id: $in: ids, (err, accounts)->
          callback err, accounts
  
  fetchFollowers: (query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    jraphical.Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JAccount.all _id: $in: ids, (err, accounts)->
          callback err, accounts
  
  fetchFollowersWithRelationship: bongo.secure (client, query, page, callback)->
    debugger
    @fetchFollowers query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback
  
  fetchFollowingWithRelationship: bongo.secure (client, query, page, callback)->
    @fetchFollowing query, page, (err, accounts)->
      if err then callback err else JAccount.markFollowing client, accounts, callback

  fetchFollowedTopics: bongo.secure (client, query, page, callback)->
    _.extend query,
      targetId  : @getId()
      as        : 'follower'
    jraphical.Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        ids = (rel.sourceId for rel in docs)
        JTag.all _id: $in: ids, (err, accounts)->
          callback err, accounts
  
  updateFollowingCount: ()->
    jraphical.Relationship.count targetId:@_id, as:'follower', (error, count)=>
      bongo.Model::update.call @, $set: 'counts.following': count, (err)->
        throw err if err
      @emit 'FollowCountChanged'
        followerCount   : @counts.followers
        followingCount  : @counts.following