_ = require 'underscore'
jraphical = require 'jraphical'

unless 'last' of Array.prototype
  Object.defineProperty Array.prototype, "last",
    get : -> this[this.length-1]

unless 'first' of Array.prototype
  Object.defineProperty Array.prototype, "first",
    get : -> this[0]

log = console.log

module.exports = class JActivityCache extends jraphical.Module

  {daisy}   = require 'bongo'

  typesToBeCached = [
    'CStatusActivity'
    'CCodeSnipActivity'
    'CFollowerBucketActivity'
    'CNewMemberBucketActivity'
    'CDiscussionActivity'
    'CTutorialActivity'
    'CBlogPostActivity'
    'CInstallerBucketActivity'
  ]

  lengthPerCache = 20
  timespan       = 120 * 60 * 60 * 1000
  cacheQueue     = []

  @share()

  @set
    indexes                 :
      to                    : 'unique'
      from                  : 'unique'
    sharedMethods           :
      static                : ["init", "createCacheFromEarliestTo"]
    schema                  :
      to                    :
        type                : Date
      from                  :
        type                : Date
      isFull                :
        type                : Boolean
        default             : no
        get                 : -> @overview.length is lengthPerCache
      overview              : Array
      activities            : Object
      newMemberBucketIndex  : Number

  defaultOptions =
    limit : 1
    sort  : to : -1

  kallback = (err, cache, callback)->
    if err        then callback err
    else if cache then callback err, cache
    else               callback null, null

  @latest = (callback)->

    @one {}, defaultOptions, (err, cache)-> kallback err, cache, callback

  @earliest = (callback)->

    options =
      limit : 1
      sort  : to : 1

    @one {}, options, (err, cache)-> kallback err, cache, callback

  @before = (timestamp, callback)->

    selector =
      to     : { $lt : new Date parseInt(timestamp,10) }

    @one selector, defaultOptions, (err, cache)-> kallback err, cache, callback

  @containsTimestamp = (timestamp, callback)->

    date     = new Date timestamp
    selector = to : { $gte : date }

    options =
      limit : 1
      sort  : to : 1

    @one selector, options, (err, cache)-> kallback err, cache, callback

  @countActivities =(callback)->
    CActivity = require './index'
    CActivity.count {}, (err, count)=>
      if err then @activityCount = 0
      else @activityCount = count
      callback()

  @init = (from, to)->    
    log "JActivityCache inits..."

    CActivity = require './index'

    @latest (err, latest)=>

      now     = Date.now()
      options = if latest
        to      : now
        from    : latest.to.getTime()
        latest  : yes
      else
        to      : to   or now
        from    : from or now - timespan

      @prepareCacheData options, (err, overview)=>
        if err
          console.warn err
          @emit "CachingFinished"
          log "caching finished.\n"
        else

          # printOverview overview

          # cap latest
          if latest and not latest.isFull

            remainderAmount   = lengthPerCache - latest.overview.length
            remainderOverview = overview.splice -remainderAmount

            cacheQueue.push ->
              latest.cap remainderOverview, ->
                log "capped latest with #{remainderOverview.length} new items!"
                cacheQueue.next()

            # cancel only if there are no new items to be cached
            if overview.length is 0
              cacheQueue.push =>
                log "caching finished.\n"
                @emit "CachingFinished"
              daisy cacheQueue
              return

          # create new cache instances
          overview2d = []

          # create batches of lengthPerCache
          while overview.length > 0
            overview2d.push overview.splice 0,lengthPerCache

          # printBatches overview2d

          @createCache overview2d, =>
            @emit "CachingFinished"
            log "caching finished.\n"


  @createCacheFromEarliestTo = (eternity)->

    @earliest (err, earliest)=>
      if err then console.warn err
      else

        unless earliest
          console.warn "there are no cache instances, run JActivityCache.init first!"
          return

        log "wohooo, going deeper in time, namely to: #{earliest.from}...\n"

      options =
        to    : earliest.from.getTime()
        from  : earliest.from.getTime() - timespan

      @prepareCacheData options, (err, overview)=>
        if err then console.warn err
        else

          # create new earlier cache instances
          # we do not include the left overs to overview2d
          overview2d = []
          while overview.length >= lengthPerCache
            overview2d.push overview.splice 0,lengthPerCache

          cb = \
            if eternity
              JActivityCache.createCacheFromEarliestTo.bind JActivityCache, yes
            else
              ->

          @createCache overview2d, cb

  @createCache = (overview2d, callback=->)->

    overview2d.forEach (cacheOverview, i)->
      cacheQueue.push ->
        JActivityCache.createInstance cacheOverview, cacheQueue.next.bind cacheQueue

    cacheQueue.push callback
    daisy cacheQueue

  processCache = (cursorArr)->
    log "processing activity cache..."
    lastDocType = null

    # group newmember buckets
    cache = cursorArr.reduce (acc, doc)->
      if doc.type is lastDocType and /NewMemberBucket/.test lastDocType
        acc.last.createdAt[1] = doc.createdAt
        if acc.last.count++ < 4
          acc.last.ids.push doc._id
      else
        acc.push
          createdAt : [doc.createdAt]
          ids       : [doc._id]
          type      : doc.type
          count     : 1
      lastDocType = doc.type
      return acc
    , []

    memberBucket   = null
    bucketIndex    = 0
    processedCache = []

    # put new member groups all together
    cache.forEach (item, i)->
      if /NewMemberBucket/.test item.type
        unless memberBucket
          memberBucket      = item
          processedCache[i] = memberBucket
          bucketIndex       = i
        else
          if processedCache[bucketIndex].ids.length < 4
            newIds = item.ids.slice 0, 4 - processedCache[bucketIndex].ids.length
            processedCache[bucketIndex].ids = processedCache[bucketIndex].ids.concat newIds
          processedCache[bucketIndex].count        += item.count
          processedCache[bucketIndex].createdAt[1]  = item.createdAt.last
      else
        processedCache.push item

    return processedCache

  @prepareCacheData = do ->

    overview  = []

    (options = {}, callback)->

      CActivity = require './index'

      unless options.to or options.from
        callback "range not specified"
        return

      options.lowQuality  ?= no
      options.types      or= typesToBeCached

      CActivity.fetchRangeForCache options, (err, cursorArr)=>
        if err then console.warn err
        else
          cache = processCache cursorArr
          overview = overview.concat cache

          if overview.length is 0
            callback "no items to be cached, cancelling..."
            return

          log "total in this batch: #{overview.length}"

          unless options.latest
            fetchMore =->
              if overview.length < lengthPerCache and @activityCount > lengthPerCache
                options.to    = options.from
                options.from -= timespan
                console.warn "last query wasn't enough asking again..."
                @prepareCacheData options, callback
                return

            unless @activityCount then @countActivities fetchMore
            else fetchMore()

          log "#{overview.length} items prepared for caching..."

          callback? null, overview.slice()
          overview = []


  @createInstance = (overview, callback)->
    @fetchOverviewTeasers overview, (err, activities)->
      if err then callback? err
      else
        to   = overview.first.createdAt.first
        from = overview.last.createdAt.last

        overviewReversed = overview.slice().reverse()

        for bucket, i in overviewReversed when bucket.type is 'CNewMemberBucketActivity'
          newMemberBucketIndex = i
          break

        instance = new JActivityCache {
          overview   : overviewReversed
          isFull     : overview.length is lengthPerCache
          newMemberBucketIndex
          activities
          from
          to
        }
        instance.save (err, inst)->
          if err then console.warn err
          else
            log "cache instance saved! from: #{instance.from} to: #{instance.to}"
            callback? null, inst[0]


  @fetchOverviewTeasers = (overview, callback)->

    CActivity = require './index'

    selector =
      snapshot : { $exists : 1 }
      _id      :
        $in    : (overview.slice().map (group)-> group.ids).reduce (a, b)-> a.concat(b)

    CActivity.some selector, {sort: createdAt: -1}, (err, activities) =>
      if err then callback? err
      else

        activityHash = {}
        for activity in activities
          actvivityId = activity._id
          activityHash[actvivityId] = activity

        callback null, activityHash


  cap: (overview, callback)->

    unless overview or (overview.length and overview.length is 0)
      return console.warn "no overview items passed to cap the activity cache instance"

    JActivityCache.fetchOverviewTeasers overview, (err, activityHash)=>
      overview.reverse()

      setModifier = Object.keys(activityHash).reduce (acc, activityId)->
        activity = activityHash[activityId]
        updatedActivity = activity.prune()
        updatedActivity.snapshotIds = [].slice.call activity.snapshotIds
        acc["activities.#{activity.getId()}"] = updatedActivity
        return acc
      , {}

      setModifier.to = overview[overview.length-1].createdAt[overview[overview.length-1].createdAt.length-1]

      freshNewMemberBucket = null
      for id, overviewItem of overview
        if overviewItem.type is 'CNewMemberBucketActivity'
          freshNewMemberBucket = overviewItem
          overview.splice(id, 1)
          break

      pushAllModifier = {overview}

      unsetModifier = {}

      if freshNewMemberBucket
        if @newMemberBucketIndex?
          newMemberBucket = @overview[@newMemberBucketIndex]
          key             = "overview.#{@newMemberBucketIndex}"

          newIds = newMemberBucket.ids.map((v,k)-> v)
            .slice(-1 * (4 - freshNewMemberBucket.ids.length))
            .concat(freshNewMemberBucket.ids)

          setModifier["#{key}.ids"]         = newIds
          setModifier["#{key}.count"]       = freshNewMemberBucket.count + newMemberBucket.count
          setModifier["#{key}.createdAt.1"] = freshNewMemberBucket.createdAt.last
        else
          index  = @overview.length
          key    = "overview.#{index}"
          newIds = freshNewMemberBucket.ids

          setModifier.newMemberBucketIndex  = index
          setModifier["#{key}.ids"]         = newIds
          setModifier["#{key}.count"]       = freshNewMemberBucket.count
          setModifier["#{key}.createdAt"]   = freshNewMemberBucket.createdAt
          setModifier["#{key}.type"]        = 'CNewMemberBucketActivity'

        # only keep CNewMemberBucketActivity's of newIds
        for id, activity of @activities
          if activity.type == 'CNewMemberBucketActivity'
            found = no
            for _id in newIds when _id.equals id
              found = yes
            unsetModifier["activities.#{id}"] = 1 if not found

        if _.size(unsetModifier)
          log "removing #{_.size(unsetModifier)} obsolete activities..."

      if overview.length
        @update $pushAll: pushAllModifier, ->

      @update
        $set:   setModifier
        $unset: unsetModifier
      , (err)-> callback?()


  @modifyByTeaser = (teaser, callback)->

    CActivity = require './index'

    {teaserId, createdAt} = teaser

    log "modifying cache instance by teaser id #{teaserId}..."

    @containsTimestamp createdAt, (err, cache)->
      if err then callback? err
      else

        return log "couldn't find cache instance!" unless cache

        # this is to get the activity
        idToUpdate = null
        for id, activity of cache.activities
          if activity.snapshotIds[0] and activity.snapshotIds[0].equals teaserId
            idToUpdate = id
            break

        CActivity.one _id : idToUpdate, (err, activity)->
          if err then callback? err
          else if activity
            setModifier = {}
            updatedActivity = activity.prune()
            # TODO: this is a workaround.  I need to look into a bug in bongo C.T.:
            updatedActivity.snapshotIds = [].slice.call updatedActivity.snapshotIds
            setModifier["activities.#{idToUpdate}"] = updatedActivity
            cache.update {$set : setModifier}, ->
              callback?()
          else
            callback?()

  @removeActivity = ({teaserId, createdAt}, callback)->

    CActivity = require './index'

    @containsTimestamp createdAt, (err, cache)->
      if err then callback? err
      else

        return log "couldn't find cache instance!" unless cache

        # this is to get the activity
        idToDelete = null
        for id, activity of cache.activities
          if activity.snapshotIds[0].equals teaserId
            idToDelete = id

        if idToDelete
          overviewIndexToDelete = null
          for item, i in cache.overview when item
            if item.ids[0].equals idToDelete
              overviewIndexToDelete = i
              break

          updateTo   = if overviewIndexToDelete is Object.keys(cache.activities).length-1 then yes else no
          updateFrom = if overviewIndexToDelete is 0 then yes else no

          unsetModifier      = {}
          setModifier        = {}
          setModifier.isFull = no
          unsetModifier["activities.#{idToDelete}"] = 1
          unsetModifier["overview.#{overviewIndexToDelete}"] = 1

          if Object.keys(cache.activities).length > 1
            if updateTo
              log "updateTo", overviewIndexToDelete
              newLastIndex   = overviewIndexToDelete - 1
              setModifier.to = cache.overview[newLastIndex].createdAt[cache.overview[newLastIndex].createdAt.length-1]

            if updateFrom
              log "updateFrom", overviewIndexToDelete
              newFirstIndex    = overviewIndexToDelete + 1
              setModifier.from = cache.overview[newFirstIndex].createdAt[0]

          cache.update
            $unset : unsetModifier
            $set   : isFull : no
          , ->
            log "activity removed from cache!", Object.keys(cache.activities).length
            cache.update
              $pullAll : { overview : [null] }
            , ->
              log "nulls in cache.overview removed"

            if Object.keys(cache.activities).length is 0
              cache.remove ->
                log "cache instance removed!"

  @cleanCacheFromActivitiesOfUser = (userId)->
    log "got task to clean cache from activities of user #{userId}"

    since = new Date()
    since.setDate(since.getDate() - timespan / 1000 / 60 / 60 / 24)

    @some {to: $gte: since}, {sort: to: 1}, (err, caches)=>
      if err then log err
      else
        return log "no caches found since #{since}... No actions performed." unless caches

        foundInCache = null
        removedCollections = 0

        queue = caches.map (cache)->->
          # look for activity of user
          if not foundInCache
            for id, activity of cache.activities
              if activity.originType == 'JAccount' and activity.originId.equals userId
                log "found activities of user in cache from #{cache.from}..."
                log "starting removing all cache collections from then..."
                foundInCache = cache

            return queue.next() unless foundInCache

          cache.remove ->
            log "removed cache collection #{cache._id}"
            removedCollections++
            queue.next()

        queue.push =>
          return log "no activities found of this user since #{since}." unless foundInCache

          log "#{removedCollections} collections removed. Re-generating cache..."

          # regenerate cache from first cache's from value
          @init(foundInCache.from)

        daisy queue

  printOverview = (overview)->
    # TEST - better not to delete this
    # logs all items' dates

    log item.createdAt[0] for item in overview when item

  printBatches = (overview2d)->
    # TEST - better not to delete this
    # logs item dates in batches

    for ov,i in overview2d
      log "batch #{i}:\n"
      printOverview ov
