jraphical      = require 'jraphical'
neo4j = require "neo4j"

module.exports = class CActivity extends jraphical.Capsule
  {Base, ObjectId, race, dash, secure} = require 'bongo'
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
    softDelete        : yes
    feedable          : yes
    broadcastable     : no
    indexes           :
      'sorts.repliesCount'  : 'sparse'
      'sorts.likesCount'    : 'sparse'
      'sorts.followerCount' : 'sparse'
      createdAt             : 'sparse'
      modifiedAt            : 'sparse'
      group                 : 'sparse'

    permissions             :
      'read activity'       : ['guest','member','moderator']

    sharedMethods     :
      static          : [
        'one','some','someData','each','cursor','teasers'
        'captureSortCounts','addGlobalListener','fetchFacets',
        'checkIfLikedBefore', 'fetchFolloweeContents', 'count'
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
      group           : String

  @on 'feed-new', (activities)->
    JGroup = require '../group'
    grouped = groupBy activities, 'group'
    for own groupName, items of grouped
      JGroup.broadcast groupName, 'feed-new', items

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
      # group        : 'koding'
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

  @fetchRangeForCache = (options = {}, callback)->
    @fetchCacheCursor options, (err, cursor)->
      if err then console.warn err
      else
        cursor.toArray (err, arr)->
          if err then callback err
          else
            callback null, arr

  @captureSortCounts =(callback)->
    selector = {
      type: {$in: ['CStatusActivity','CLinkActivity','CCodeSnipActivity',
                   'CDiscussionActivity','COpinionActivity',
                   'CCodeShareActivity','CTutorialActivity',
                   'CBlogPostActivity']}
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

  defaultFacets = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
      'CDiscussionActivity'
      'CTutorialActivity'
      'CInstallerBucketActivity'
      'CBlogPostActivity'
    ]

  @fetchFacets = permit 'read activity',
    success:(client, options, callback)->
      {to, limit, facets, lowQuality, originId} = options

      lowQuality  ?= yes
      facets      ?= defaultFacets
      to          ?= Date.now()

      selector =
        type         : { $in : facets }
        createdAt    : { $lt : new Date to }
        isLowQuality : { $ne : lowQuality }
        group        : client.groupName ? 'koding'

      selector.originId = originId if originId

      options =
        limit : limit or 20
        sort  : createdAt : -1

      @some selector, options, (err, activities)->
        if err then callback err
        else

          # When the snapshot already contains &quot;, those will be
          # decoded once the client receives them (along with the " that
          # are encoded for the server-client transmission). That's why
          # they are converted into \" here.              02/28/13 Arvid

          for own index,activity of activities
            if activity.snapshot
              activities[index].snapshot = activities[index].snapshot.replace(/(&quot;)/g, '\\"')

          callback null, activities

  @fetchObjectsFromMongo:(collections, wantedOrder, callback)->

    console.log(collections)

    sortThem:(err, objects) ->
      console.log("finished!!!!")

    ret = []
    collectObjects = race (i, res, fin)->
      res.klass.all res.selector, (err, objects)->
      if err then callback err
      else
        console.log("the error >>>>>: " + err)
        console.log("the objects >>>>>: ")
        console.log(objects)
        for o in objects
          ret.push(o)
      fin()
    , -> sortThem null, ret

    for modelName of collections
      ids = collections[modelName]
      klass = Base.constructors[modelName]
      selector = {
        _id:
          $in: ids.map (id)->
            if 'string' is typeof id then ObjectId(id)
            else id
      }
      collectObjects({klass:klass, selector:selector})


  @fetchFolloweeContents:(params={}, callback)->
    neo4jConfig = KONFIG['neo4j']
    params['userId'] = "502348600a6f5e381a000005"

    @db = new neo4j.GraphDatabase(neo4jConfig.host + ":" + neo4jConfig.port);

    query = ['start koding=node:koding(id={userId})'
             'MATCH koding<-[:follower]-myfollowees-[:creator]->items'
             'where myfollowees.name="JAccount"'
             'return myfollowees, items'
             'order by items.`meta.createdAt` DESC'
             'LIMIT 100'
            ].join('\n')

    @db.query query, params, (err, results)=>
      console.log("err:" + err)
      if err then return callback err
      console.log "result:" + results
      wants_in_order = []
      collections = {
      }
      for result in results
#        console.log "=============================="
#        console.log JSON.stringify(result)
#        console.log "------------------------------"
#        console.log result["items"]["_data"]["data"]["id"]
#        console.log "=============================="
        oid = result["items"]["_data"]["data"]["id"]
        otype = result["items"]["_data"]["data"]["name"]
        wants_in_order.push({id: oid, collection: otype, idx: oid+'_'+otype})
        collections[otype] ||= []
        collections[otype].push(oid)

      console.log("!!!!!!!!")
      myobjects = @fetchObjectsFromMongo(collections, wants_in_order)
      console.log("done")
      callback null, "xx"

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
        likedIds = []
        for likedRel in likedRels
          likedIds.push likedRel.sourceId

        callback err, likedIds
