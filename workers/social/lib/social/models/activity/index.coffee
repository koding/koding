jraphical = require 'jraphical'

module.exports = class CActivity extends jraphical.Capsule
  {Base, ObjectId, race, dash, secure} = require 'bongo'
  {Relationship} = jraphical

  @getFlagRole =-> 'activity'

  jraphical.Snapshot.watchConstructor @

  @share()

  @trait __dirname, '../../traits/followable', override: no

  @set
    feedable          : yes
    # indexes           :
    #   'sorts.repliesCount'  : 'sparse'
    #   'sorts.likesCount'    : 'sparse'
    #   'sorts.followerCount' : 'sparse'
    sharedMethods     :
      static          : [
        'one','some','all','someData','each','cursor','teasers'
        'captureSortCounts','addGlobalListener','fetchActivityOverview'
        'createActivityCache'
      ]
      instance        : ['fetchTeaser']
    schema            :
      # teaserSnapshot  : Object
      sorts           :
        repliesCount  :
          type        : Number
          default     : 0
        likesCount    :
          type        : Number
          default     : 0
        followerCount :
          type        : Number
          default     : 0
      isLowQuality    : Boolean
      snapshot        : String
      snapshotIds     : [ObjectId]
      createdAt       :
        type          : Date
        default       : -> new Date
      modifiedAt      :
        type          : Date
        get           : -> new Date
      originType      : String
      originId        : ObjectId

  # @__migrate =(callback)->
  #   @all {snapshot: $exists: no}, (err, activities)->
  #     console.log('made it here')
  #     if err
  #       callback err
  #     else
  #       activities.forEach (activity)->
  #         activity.fetchSubject (err, subject)->
  #           if err
  #             callback err
  #           else
  #             subject.fetchTeaser (err, teaser)->
  #               if err
  #                 callback err
  #               else
  #                 activity.update
  #                   $set:
  #                     snapshot: JSON.stringify(teaser)
  #                   $addToSet:
  #                     snapshotIds: subject.getId()
  #                 , callback


  @fetchCursor =(options = {}, callback)->

    {to, from, lowQuality, types, limit, sort} = options

    selector =
      createdAt    :
        $lte       : new Date to
        $gte       : new Date from
      type         :
        $in        : types
      isLowQuality :
        $ne        : lowQuality

    fields  =
      type      : 1
      createdAt : 1

    options =
      sort  : sort  or {createdAt: -1}
      limit : limit or 1000

    @someData selector, fields, options, (err, cursor)->
      if err then callback err
      else
        callback cursor

  @fetchActivityOverview = (options, callback)->
    @fetchCursor options, (cursor)->
      cursor.toArray (err, arr)->
        if err then callback err
        else
          lastDocType = null
          obj = arr.reduce (acc, doc)->
            if doc.type is lastDocType
              acc[acc.length-1].createdAt.push doc.createdAt

              if /NewMemberBucket/.test doc.type
                if acc[acc.length-1].count++ < 3
                  acc[acc.length-1].ids.push doc._id
              else
                acc[acc.length-1].ids.push doc._id

            else
              acc.push
                createdAt  : [doc.createdAt]
                ids        : [doc._id]
                type       : doc.type
                count      : 1
            lastDocType = doc.type
            return acc
          , []
          callback null, obj

  @fetchActivityCache =(options = {}, callback)->
    @fetchCursor options, (cursor)->
      cursor.toArray (err, arr)->
        if err then callback err
        else
          lastDocType = null
          cache = arr.reduce (acc, doc)->
            if doc.type is lastDocType and /NewMemberBucket/.test lastDocType
              acc[acc.length-1].createdAt[1] = doc.createdAt
              if acc[acc.length-1].count++ < 3
                acc[acc.length-1].ids.push doc._id
            else
              acc.push
                createdAt  : [doc.createdAt]
                ids        : [doc._id]
                type       : doc.type
                count      : 1
            lastDocType = doc.type
            return acc
          , []
          callback null, cache


  @createActivityCache = do ->

    activityTypesToBeCached = [
        'CStatusActivity'
        'CCodeSnipActivity'
        'CFollowerBucketActivity'
        'CNewMemberBucketActivity'
        'CDiscussionActivity'
        'CTutorialActivity'
        'CInstallerBucketActivity'
      ]

    allowedLengthPerFile = 50
    timespan             = 1 * 60 *60 * 1000
    lastTo               = null
    lastFrom             = null

    (options)->

      now        = Date.now()
      lastTo     = if lastTo   then lastFrom else now
      lastFrom   = if lastFrom then lastFrom - timespan else now - timespan

      options =
        lowQuality : no
        from       : options.from or lastFrom
        to         : options.to   or lastTo
        types      : activityTypesToBeCached
        # limit      : 100

      cachedItems = []

      CActivity.fetchActivityCache options, (err, cache)=>
        if err then console.warn err
        else
          console.log i, item.count, item.createdAt for item, i in cache

          # if cache.length < 50




          # totalLength = overview.length + cachedItems.length

          # if totalLength is allowedLengthPerFile
          #   console.log cachedItems

          # else if totalLength < allowedLengthPerFile
          #   cachedItems.concat overview
          #   nextFrom = cachedItems[overview.length-1].createdAt[0]
          #   nextTo   = cachedItems[overview.length-1].createdAt[1]

          # else if totalLength > allowedLengthPerFile
          #   remainderCount = cachedItemsPerFile - cachedItems.length
          #   remainder      = overview[..remainderCount]
          #   cachedItems.concat remainder



  @on "feed-new", @createActivityCache.bind @

  @captureSortCounts =(callback)->
    selector = {
      type: {$in: ['CStatusActivity','CLinkActivity','CCodeSnipActivity','CDiscussionActivity','COpinionActivity','CCodeShareActivity','CTutorialActivity']}
      $or: [
        {'sorts.repliesCount' : $exists:no}
        {'sorts.likesCount'   : $exists:no}
      ]
    }
    @someData selector, {
      _id: 1
    }, (err, cursor)->
      if err
        callback err
      else
        queue = []
        cursor.each (err, doc)->
          if err
            callback err
          else unless doc?
            dash queue, callback
          else
            {_id} = doc
            queue.push ->
              selector2 = {
                sourceId  : _id
                as        : 'content'
              }
              Relationship.someData selector2, {
                targetName  : 1
                targetId    : 1
              }, (err, cursor)->
                if err
                  callback err
                else
                  cursor.nextObject (err, doc1)->
                    if err
                      queue.fin(err)
                    else unless doc1?
                      console.log _id, JSON.stringify selector2
                    else
                      {targetName, targetId} = doc1
                      Base.constructors[targetName].someData {
                        _id: targetId
                      },{
                        'repliesCount'  : 1
                        'meta'          : 1
                      }, (err, cursor)->
                        if err
                          queue.fin(err)
                        else
                          cursor.nextObject (err, doc2)->
                            if err
                              queue.fin(err)
                            else
                              {repliesCount, meta} = doc2
                              op = $set:
                                 'sorts.repliesCount' : repliesCount
                                 'sorts.likesCount'   : meta?.likes or 0
                              CActivity.update {_id}, op, -> queue.fin()

  fetchTeaser:(callback)->
    @fetchSubject (err, subject)->
      if err
        callback err
      else
        subject.fetchTeaser (err, teaser)->
          callback err, teaser

  @teasers =(selector, options, callback)->
    [callback, options] = [options, callback] unless callback
    @someData {snapshot:$exists:1}, {snapshot:1}, {limit:20}, (err, cursor)->
      cursor.toArray (err, arr)->
        callback null, 'feed:'+(item.snapshot for item in arr).join '\n'

  markAsRead: secure ({connection:{delegate}}, callback)->
    @update
      $addToSet: readBy: delegate.getId()
    , callback
