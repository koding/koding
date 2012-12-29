jraphical = require 'jraphical'

unless Array.prototype.last
  Object.defineProperty Array.prototype, "last",
    get : -> this[this.length-1]

unless Array.prototype.first
  Object.defineProperty Array.prototype, "first",
    get : -> this[0]

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
  timespan       = 120 * 60 *60 * 1000

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
        default   : -> new Date
        get       : -> this.overview[0].createdAt[0]
      from        :
        type      : Date
        default   : -> new Date
        get       : ->
          last = this.overview[this.overview.length-1]
          last.createdAt[last.createdAt.length-1]
      isFull      :
        type      : Boolean
        default   : no
        get       : -> this.overview.length is lengthPerCache
      overview    : Array
      activities  : Array

  latestFetched = null

  o =
    limit : 1
    sort  : to : -1

  kallback = (err, cache, callback)->
    if err
      callback err
    else if cache
      latestFetched = if cache then cache
      # console.log latestFetched?.to
      callback err, cache
    else
      callback null, null


  @latest = (callback)->

    @one {}, o, (err, cache)-> kallback err, cache, callback

  @earliest = (callback)->

    options =
      limit : 1
      sort  : to : 1

    @one {}, options, (err, cache)-> kallback err, cache, callback

  @next = (callback)->

    return @latest callback  unless latestFetched

    selector = from : $gt : latestFetched.to.getTime()

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @prev = (callback)->

    return @latest callback  unless latestFetched

    selector = to : $lt : latestFetched.from.getTime()

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @byId = (id, callback)->

    selector = _id : id

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @containsTimestamp = (timestamp, callback)->

    selector = to : $gte : timestamp

    @one selector, o, (err, cache)-> kallback err, cache, callback

  # create initial activity cache
  # FIXME: this would fail if there are more than 1000 activities
  # between from and to
  @init = (from, to)->

    console.log "JActivityCache init...\n"

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

          # TEST - better not to delete this
          # logs all items' dates

          # console.log item.createdAt[0] for item in overview
          # return

          # cap latest
          if latest and latest.overview.length < lengthPerCache

            # return console.log "capping latest...."
            remainderAmount   = lengthPerCache - latest.overview.length
            remainderOverview = overview.splice -remainderAmount

            latest.cap remainderOverview, ->
              console.log "capped latest and finished!"

            return  if remainderOverview.length <= remainderAmount




          # create new cache instances
          overview2d = []

          # splice remainders amount of newest items to
          # finish the batch with even lengthPerCache items
          overview2d.push overview.splice 0, overview.length%lengthPerCache

          # create batches of lengthPerCache
          while overview.length >= lengthPerCache
            overview2d.push overview.splice 0,lengthPerCache

          # TEST - better not to delete this
          # logs item dates in batches

          for ov,i in overview2d
            console.log "batch #{i}:\n"
            for it in ov
              console.log it.createdAt[0]

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
          overview   : overview.slice()
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
            callback? null, inst


  @fetchOverviewTeasers = (overview, callback)->

    CActivity = require './index'

    selector =
      _id    :
        $in  : (overview.map (group)-> group.ids).reduce (a, b)-> a.concat(b)

    CActivity.some selector, {sort: createdAt: -1}, (err, activities) =>
      if err then callback? err
      else
        callback null, activities

  cap : (overview, callback)->

    unless overview or (overview.length and overview.length is 0)
      return console.warn "no overview items passed to cap the activity cache instance"


    latestOverview = []

    @overview.forEach (o)->
      createdAt = []
      ids       = []
      o.createdAt.forEach (c)-> createdAt.push c
      o.ids.forEach (id)-> ids.push id

      latestOverview.push {
        type      : o.type
        count     : o.count
        createdAt
        ids
      }

    overview.reverse().forEach (oItem)-> latestOverview.unshift oItem

    # return console.log latestOverview

    # unfortunately whatever i tried update didn't work
    # so i'm deleting the instance first and recreating the new one :|

    JActivityCache.createInstance latestOverview, (err, inst)=>
      if err then console.warn err
      else

        return console.log "cache instance capped to #{inst.overview.length}!"
        JActivityCache.remove { _id : @getId()}, (err)->
          if err then console.warn err
          callback err




    # JActivityCache.fetchOverviewTeasers overview, (err, activities)->

    #   console.log latest.overview.length, latest.activities.length

    #   latestActivities = [].slice.apply latest.activities

    #   activities.reverse().forEach (aItem)-> latestActivities.unshift aItem

    #   console.log latestOverview.length, latestActivities.length

    #   updateOptions =
    #     '$set' :
    #       'to'         : latestOverview.first.createdAt.first
    #       'from'       : latestOverview.last.createdAt.last
    #       'isFull'     : latestOverview.length is lengthPerCache
    #       'overview'   : latestOverview
    #       'activities' : latestActivities

    #   latest.update updateOptions, (err, inst)->
    #     if err then console.warn err
    #     else console.log "cache instance capped to #{inst.overview.length}!"







  # createInitialCache
  # do ->
  #   console.log "zikkimi >>>>"












