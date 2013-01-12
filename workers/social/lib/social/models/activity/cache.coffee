jraphical = require 'jraphical'

unless Array.prototype.last
  Object.defineProperty Array.prototype, "last",
    get : -> this[this.length-1]

unless Array.prototype.first
  Object.defineProperty Array.prototype, "first",
    get : -> this[0]

log = console.log

module.exports = class JActivityCache extends jraphical.Module

  {daisy}   = require 'bongo'
  # CActivity = require './index'

  typesToBeCached = [
    'CStatusActivity'
    'CCodeSnipActivity'
    'CFollowerBucketActivity'
    'CNewMemberBucketActivity'
    'CDiscussionActivity'
    'CTutorialActivity'
    'CInstallerBucketActivity'
  ]

  lengthPerCache = 20
  timespan       = 120 * 60 * 60 * 1000

  @share()

  @set
    indexes       :
      to          : 'unique'
    sharedMethods :
      static      : ["latest", "init", "createCacheFromEarliestTo"]
      instance    : []
    schema        :
      # name        : String
      to          :
        type      : Date
      from        :
        type      : Date
      isFull      :
        type      : Boolean
        default   : no
        get       : -> this.overview.length is lengthPerCache
      overview    : Array
      activities  : Object

  defaultOptions =
    limit : 1
    sort  : to : -1

  kallback = (err, cache, callback)->
    if err
      callback err
    else if cache
      callback err, cache
    else
      callback null, null


  @latest = (callback)->

    @one {}, defaultOptions, (err, cache)-> kallback err, cache, callback

  @earliest = (callback)->

    options =
      limit : 1
      sort  : to : 1

    @one {}, options, (err, cache)-> kallback err, cache, callback

  @before = (timestamp, callback)->

    selector =
      to     : { $lt : new Date(parseInt(timestamp,10)) }

    @one selector, defaultOptions, (err, cache)-> kallback err, cache, callback

  @byId = (id, callback)->

    selector = _id : id

    @one selector, defaultOptions, (err, cache)-> kallback err, cache, callback

  @containsTimestamp = (timestamp, callback)->

    selector =
      to     : { $gte : new Date(timestamp) }
      from   : { $lte : new Date(timestamp) }

    @one selector, defaultOptions, (err, cache)-> kallback err, cache, callback

  # create initial activity cache
  # FIXME: this would fail if there are more than 1000 activities
  # between from and to
  @init = (from, to)->

    console.log "JActivityCache inits...\n"

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
        if err then console.warn err
        else

          ###
          # TEST - better not to delete this
          # logs all items' dates

          console.log item.createdAt[0] for item in overview
          return
          ###

          # cap latest
          if latest and not latest.isFull

            # return console.log "capping latest...."
            remainderAmount   = lengthPerCache - latest.overview.length
            remainderOverview = overview.splice -remainderAmount

            # log remainderOverview
            # return
            latest.cap remainderOverview, -> console.log "capped latest!"

            # terminate only if there are no new items to be cached
            return  if overview.length is 0

          # create new cache instances
          overview2d = []

          # splice remainders amount of newest items to
          # finish the batch with even lengthPerCache items
          overview2d.push overview.splice 0, overview.length%lengthPerCache

          # create batches of lengthPerCache
          while overview.length >= lengthPerCache
            overview2d.push overview.splice 0,lengthPerCache

          ###
          # TEST - better not to delete this
          # logs item dates in batches

          for ov,i in overview2d
            console.log "batch #{i}:\n"
            for it in ov
              console.log it.createdAt[0]
          ###

          @createCache overview2d

  @createCacheFromEarliestTo = (to)->

    @earliest (err, earliest)=>
      if err then console.warn err
      else

        unless earliest
          console.warn "there are no cache instances, run JActivityCache.init first!"
          return

        console.log "wohooo, going deeper in time, namely to: #{earliest.from}...\n"

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

          @createCache overview2d

  @createCache = (overview2d)->

    queue    = []
    {length} = queue
    overview2d.forEach (cacheOverview, i)->
      queue.push ->
        JActivityCache.createInstance cacheOverview, queue.next.bind queue

    daisy queue

  @prepareCacheData = do ->

    overview  = []

    (options = {}, callback)->

      CActivity = require './index'

      unless options.to or options.from
        callback "range not specified"
        return

      options.lowQuality  ?= no
      options.types      or= typesToBeCached

      CActivity.fetchRangeForCache options, (err, cache)=>
        if err then console.warn err
        else
          overview = overview.concat cache

          if overview.length is 0
            callback "no items to be cached, terminating..."
            return

          console.log "total in this batch: #{overview.length}"

          if not options.latest and overview.length < lengthPerCache
            options.to    = options.from
            options.from -= timespan
            console.warn "last query wasn't enough asking again...\n"
            @prepareCacheData options, callback
            return

          console.log "#{overview.length} items prepared for caching...\n"

          callback? null, overview.slice()
          overview = []


  @createInstance = (overview, callback)->

    @fetchOverviewTeasers overview, (err, activities)->
      if err then callback? err
      else
        to   = overview.first.createdAt.first
        from = overview.last.createdAt.last

        instance = new JActivityCache {
          overview   : overview.slice().reverse()
          isFull     : overview.length is lengthPerCache
          activities
          from
          to
        }

        # console.log instance
        # console.log "\n", o for o in overview

        instance.save (err, inst)->
          if err then console.warn err
          else
            console.log "cache instance saved! from: #{instance.from} to: #{instance.to}"
            callback? null, inst[0]


  @fetchOverviewTeasers = (overview, callback)->

    CActivity = require './index'

    selector =
      _id    :
        $in  : (overview.slice().map (group)-> group.ids).reduce (a, b)-> a.concat(b)

    CActivity.some selector, {sort: createdAt: -1}, (err, activities) =>
      if err then callback? err
      else

        activityHash = {}
        for activity in activities
          # activityHash[activity.snapshotIds[0]] = activity
          actvivityId = activity._id
          activityHash[actvivityId] = activity

        callback null, activityHash


        # activityHash[activity._id] = activity for activity in activities

        # groupedActivities = []
        # for item in overview
        #   if item.ids.length > 1
        #     subGroup = (activityHash[id] for id in item.ids)
        #     groupedActivities.push subGroup
        #   else
        #     groupedActivities.push [activityHash[item.ids.first]]

        # callback null, groupedActivities


  cap: (overview, callback)->

    unless overview or (overview.length and overview.length is 0)
      return console.warn "no overview items passed to cap the activity cache instance"

    JActivityCache.fetchOverviewTeasers overview, (err, activityHash)=>

      overview.reverse()

      # activityMissed = no

      activitiesModifier = Object.keys(activityHash).reduce (acc, activityId)->
        activity = activityHash[activityId]
        updatedActivity = activity.prune()
        # log activity, activity.snapshotIds
        if activity.snapshotIds
          updatedActivity.snapshotIds = [].slice.call activity.snapshotIds
          acc["activities.#{activity.getId()}"] = updatedActivity
        # else
        #   activityMissed = yes
        return acc
      , {}

      # if activityMissed
      #   log "an activity couldn't be cached, trying again in a sec!"
      #   setTimeout =>
      #     @cap overview, callback
      #   , 1000
      #   return

      activitiesModifier.to = overview[overview.length-1].createdAt[overview[overview.length-1].createdAt.length-1]

      @update {
        $pushAll: {overview}
        $set    : activitiesModifier
      }, (err)-> callback?()


  @modifyByTeaser = (teaser, callback)->

    CActivity = require './index'

    # log "ever here", teaser.meta.createdAt

    @containsTimestamp teaser.meta.createdAt, (err, cache)->
      if err then callback? err
      else

        return log "couldn't find cache instance!" unless cache

        # this is to get the activity
        idToUpdate = null
        for id, activity of cache.activities
          if activity.snapshotIds[0].equals teaser.getId()
            idToUpdate = id
            # log "found the activity, now perform an atomic update to:", id

        CActivity.one _id : idToUpdate, (err, activity)->
          if err then callback? err
          else
            setModifier = {}
            updatedActivity = activity.prune()
            # TODO: this is a workaround.  I need to look into a bug in bongo C.T.:
            updatedActivity.snapshotIds = [].slice.call updatedActivity.snapshotIds
            setModifier["activities.#{idToUpdate}"] = updatedActivity
            cache.update {$set : setModifier}, -> #console.log.bind(console)






