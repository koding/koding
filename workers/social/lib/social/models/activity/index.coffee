jraphical      = require 'jraphical'
JActivityCache = require './cache'

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
        'captureSortCounts','addGlobalListener','fetchFacets'
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

  @fetchCacheCursor =(options = {}, callback)->

    {to, from, lowQuality, types, limit, sort} = options

    selector =
      createdAt    :
        $lt        : new Date to
        $gt        : new Date from
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
        callback null, cursor

  processCache = (cursorArr)->
    console.log "processing activity cache..."
    lastDocType = null

    # group newmember buckets
    cache = cursorArr.reduce (acc, doc)->
      if doc.type is lastDocType and /NewMemberBucket/.test lastDocType
        acc.last.createdAt[1] = doc.createdAt
        if acc.last.count++ < 3
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
          processedCache[bucketIndex].ids = processedCache[bucketIndex].ids.concat item.ids
          processedCache[bucketIndex].count += item.count
          processedCache[bucketIndex].createdAt[1] = item.createdAt.last
      else
        processedCache.push item

    return processedCache

  @fetchRangeForCache = (options = {}, callback)->
    @fetchCacheCursor options, (err, cursor)->
      if err then console.warn err
      else
        cursor.toArray (err, arr)->
          if err then callback err
          else
            callback null, processCache arr


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

  @fetchFacets = (options, callback)->

    {to, limit, facets, lowQuality} = options

    selector =
      type         : { $in : facets }
      createdAt    : { $lt : new Date to }
      isLowQuality : { $ne : lowQuality }

    options =
      limit : limit or 20
      sort  : createdAt : -1


    console.log JSON.stringify selector

    @some selector, options, (err, activities)->
      if err then callback err
      else
        callback null, activities


  markAsRead: secure ({connection:{delegate}}, callback)->
    @update
      $addToSet: readBy: delegate.getId()
    , callback


# temp, couldn't find a better place to put this

do ->
  typesToBeCached = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
      'CDiscussionActivity'
      'CTutorialActivity'
      'CInstallerBucketActivity'
    ]

  CActivity.on "ActivityIsCreated", (activity)->
    console.log "ever here", activity.constructor.name
    if activity.constructor.name in typesToBeCached
      JActivityCache.init()

  CActivity.on "post-updated", (teaser)->
    JActivityCache.modifyByTeaser teaser

  CActivity.on "BucketIsUpdated", (activity, bucket)->
    console.log bucket.constructor.name, "is being updated"
    if activity.constructor.name in typesToBeCached
      JActivityCache.modifyByTeaser bucket

  console.log "\"feed-new\" event for Activity Caching is bound."
  console.log "\"post-updated\" event for Activity Caching is bound."

