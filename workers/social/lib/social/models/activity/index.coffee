jraphical      = require 'jraphical'
KodingError = require '../../error'

module.exports = class CActivity extends jraphical.Capsule
  {Base, ObjectId, race, dash, secure, signature} = require 'bongo'
  {Relationship} = jraphical

  {groupBy} = require 'underscore'

  {permit} = require '../group/permissionset'

  @getFlagRole =-> 'activity'

  jraphical.Snapshot.watchConstructor this

  @share()

  @trait __dirname, '../../traits/followable', override: no
  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/restrictedquery'
  @trait __dirname, '../../traits/grouprelated'

  @set
    softDelete        : no
    feedable          : yes
    broadcastable     : no
    indexes           :
      'sorts.repliesCount'  : 'sparse'
      'sorts.likesCount'    : 'sparse'
      'sorts.followerCount' : 'sparse'
      createdAt       : 'sparse'
      modifiedAt      : 'sparse'
      group           : 'sparse'
    sharedEvents      :
      instance        : []
      static          : ['BucketIsUpdated', 'cacheWorker'
                         'ActivityIsCreated']
    sharedMethods     :
      static          :
        fetchFolloweeContents:
          (signature Object, Function)
        one:
          (signature Object, Function)
        some:
          (signature Object, Object, Function)
        someData: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        each: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        cursor:
          (signature Object, Object, Function)
        teasers: [
          (signature Function)
          (signature Object, Function)
        ]
        checkIfLikedBefore:
          (signature [String], Function)
        count: [
          (signature Function)
          (signature Object, Function)
        ]
        fetchCount:
          (signature Function)
        fetchLastActivityTimestamp:
          (signature Function)
      instance        :
        fetchTeaser: [
          (signature Function)
          (signature Function, Boolean)
        ]

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
      group           : String

  @fetchLastActivityTimestamp = (callback) ->
    selector  = {}
    fields    = createdAt: 1
    options   = limit:1, sort: createdAt: -1
    @each selector, fields, options, (err, item)->
      return callback err  if err
      callback null, +item.createdAt  if item?


  fetchTeaser:(callback, showIsLowQuality=no)->
    @fetchSubject (err, subject)->
      if err
        callback err
      else if subject
        subject.fetchTeaser (err, teaser)->
          callback err, teaser
        , showIsLowQuality
      else
        callback null, null

  @teasers =(selector, options, callback)->
    [callback, options] = [options, callback] unless callback
    @someData {snapshot:$exists:1}, {snapshot:1}, {limit:20}, (err, cursor)->
      cursor.toArray (err, arr)->
        callback null, 'feed:'+(item.snapshot for item in arr).join '\n'

  markAsRead: secure ({connection:{delegate}}, callback)->
    @update
      $addToSet: readBy: delegate.getId()
    , callback

  @checkIfLikedBefore: secure ({connection}, idsToCheck, callback)->
    {delegate} = connection
    if not delegate
      callback null, no
    else
      Relationship.some
        sourceId: {$in: idsToCheck}
        targetId: delegate.getId()
        as: 'like'
      , {}, (err, likedRels)=>
        callback err, (likedRel.sourceId for likedRel in likedRels)

  notifyCache = (event, contents)->
    routingKey = contents.group or 'koding'
    @emit 'cacheWorker', {routingKey, event, contents}

  @on 'ActivityIsCreated', notifyCache.bind this, 'ActivityIsCreated'
  @on 'PostIsUpdated',     notifyCache.bind this, 'PostIsUpdated'
  @on 'PostIsDeleted',     notifyCache.bind this, 'PostIsDeleted'
  @on 'BucketIsUpdated',   notifyCache.bind this, 'BucketIsUpdated'
  @on 'UserMarkedAsTroll', notifyCache.bind this, 'UserMarkedAsTroll'
