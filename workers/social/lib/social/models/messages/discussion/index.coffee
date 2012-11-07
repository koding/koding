JPost = require '../post'

module.exports = class JDiscussion extends JPost

  # @mixin Followable
  # @::mixin Followable::
  # @::mixin Taggable::
  # @::mixin Notifying::
  # @mixin Flaggable
  # @::mixin Flaggable::
  # @::mixin Likeable::

  {Base,ObjectId,ObjectRef,secure,dash,daisy} = require 'bongo'
  {Relationship} = require 'jraphical'

  {log} = console

  {once} = require 'underscore'

  @share()

  @getActivityType =-> require './discussionactivity'

  @getAuthorType =-> require '../../account'

  @getFlagRole =-> ['sender', 'recipient']
  @set
    emitFollowingActivities: yes
    taggedContentRole : 'post'
    tagRole           : 'tag'
    sharedMethods     :
      static          : ['create','one']
      instance        : [
        'on','reply','restComments','commentsByRange'
        'like','checkIfLikedBefore','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments'
        'updateTeaser'
      ]
    schema        : JPost.schema
    relationships     :
      opinion         :
        targetType    : "JOpinion"
        as            : 'opinion'
      participant     :
        targetType    : "JAccount"
        as            : ['author','commenter']
      likedBy         :
        targetType    : "JAccount"
        as            : 'like'
      repliesActivity :
        targetType    : "CRepliesActivity"
        as            : 'repliesActivity'
      tag             :
        targetType    : "JTag"
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : "JAccount"

  @create = secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost.create.call @, client, discussion, callback

  modify: secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, discussion, callback

  removeReply:(rel, callback)->
    id = @getId()
    teaser = null
    activityId = null
    repliesCount = @getAt 'repliesCount'
    queue = [
      ->
        rel.update $set: 'data.deletedAt': new Date, -> queue.next()
      =>
        @update $inc: repliesCount: -1, -> queue.next()
      =>
        @flushSnapshot rel.getAt('targetId'), -> queue.next()
      =>
        @emit 'ReplyIsRemoved', rel.targetId
        queue.next()
      callback
    ]
    daisy queue

  reply: secure (client, comment, callback)->
    {delegate} = client.connection

    JAccount = require '../../account'

    unless delegate instanceof JAccount
      callback new Error 'Log in required!'
    else
      JComment = require '../comment'
      JOpinion = require '../opinion'

      comment = new JOpinion
        body: comment.body
        title: comment.body
        meta: comment.meta
      exempt = delegate.checkFlag('exempt')
      if exempt
        comment.isLowQuality = yes
      comment
        .sign(delegate)
        .save (err)=>
          if err
            callback err
          else
            delegate.addContent comment, (err)->
              if err
                log 'JDiscussion error adding content to delegate', err
            @addOpinion comment,
              flags:
                isLowQuality    : exempt
            , (err, docs)=>
              if err
                callback err
              else
                if exempt
                  callback null, comment
                else
                  Relationship.count {
                    sourceId                    : @getId()
                    as                          : 'opinion'
                    'data.flags.isLowQuality'   : $ne: yes
                  }, (err, count)=>
                    if err
                      callback err
                    else
                      @update $set: repliesCount: count, (err)=>
                        if err
                          callback err
                        else
                          callback null, comment
                          @fetchActivityId (err, id)->

                            CActivity = require '../../activity'

                            CActivity.update {_id: id}, {
                              $set:
                                'sorts.repliesCount'  : count
                            }, log
                          @fetchOrigin (err, origin)=>
                            if err
                              log "Couldn't fetch the origin"
                            else
                              unless exempt
                                @emit 'ReplyIsAdded', {
                                  origin
                                  subject       : ObjectRef(@).data
                                  actorType     : 'replier'
                                  actionType    : 'opinion'
                                  replier       : ObjectRef(delegate).data
                                  opinion       : ObjectRef(comment).data
                                  repliesCount  : count
                                  relationship  : docs[0]
                                  # opinionData   : JSON.stringify comment
                                }
                              @follow client, emitActivity: no, (err)->
                              @addParticipant delegate, 'commenter', (err)-> #TODO: what should we do with this error?

  updateTeaser:(callback)->
    activity = null
    teaser_ = null
    id_ = @getId()
    daisy queue = [
      =>
        @fetchActivity (err, id)->
          activity = id
          queue.next()
      =>
        @fetchTeaser (err, teaser)->
          teaser_ = teaser
          activity.update
            $set:
              snapshot: JSON.stringify teaser_
            $addToSet:
              snapshotIds: id_
          ,(err, result)->
            if err
              log "update err", err, result
            queue.next()
      =>
        callback? null, teaser_
    ]

  fetchTeaser:(callback)->
    @beginGraphlet()
      .edges
        query         :
          sourceName  : 'JDiscussion'
          targetName  : 'JTag'
          as          : 'tag'
        limit         : 5
      .and()
      .edges
        query         :
          targetName  : 'JOpinion'
          as          : 'opinion'
          'data.deletedAt':
            $exists   : no
          'data.flags.isLowQuality':
            $ne       : yes
        limit         : 5
        sort          :
          timestamp   : 1
      .nodes()
      .edgesOfEach
        query         :
          sourceName  : 'JOpinion'
          targetName  : 'JComment'
          as          : 'reply'
          'data.deletedAt':
            $exists   : no
          'data.flags.isLowQuality':
            $ne       : yes
        limit         : 3
        sort          :
          timestamp   : 1
      .nodes()
    .endGraphlet()
    .fetchRoot callback

  fetchRelativeComments:({limit, before, after}, callback)->
    limit ?= 10
    if before? and after?
      callback new KodingError "Don't use before and after together."
    selector = timestamp:
      if before? then  $lt: before
      else if after? then $gt: after
    selector['data.flags.isLowQuality'] = $ne: yes
    options = {limit, sort: timestamp: 1}
    @fetchOpinions selector, options, callback

  commentsByRange:(options, callback)->
    [callback, options] = [options, callback] unless callback
    {from, to} = options
    from or= 0
    if from > 1e6
      selector = timestamp:
        $gte: new Date from
        $lte: to or new Date
      queryOptions = {}
    else
      to or= Math.max()
      selector = {}
      queryOptions = skip: from
      if to
        queryOptions.limit = to - from
    selector['data.flags.isLowQuality'] = $ne: yes
    queryOptions.sort = timestamp: 1
    @fetchOpinions selector, queryOptions, callback

  restComments:(skipCount, callback)->
    [callback, skipCount] = [skipCount, callback] unless callback
    skipCount ?= 3

    @fetchOpinions {
      'data.flags.isLowQuality': $ne: yes
    },
      skip: skipCount
      sort:
        timestamp: 1
    , (err, comments)->
      if err
        log "err is ", err
        callback err
      else
        # log "restcomment comments are",comments
        # comments.reverse()
        callback null, comments

  fetchEntireMessage:(callback)->
    @beginGraphlet()
      .edges
        query         :
          targetName  :'JOpinion'
        sort          :
          timestamp   : 1
      .nodes()
    .endGraphlet()
    .fetchRoot callback