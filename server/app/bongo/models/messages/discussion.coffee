class JOpinion extends JPost
  @mixin Followable
  @::mixin Followable::
  @::mixin Taggable::
  @::mixin Notifying::
  @mixin Flaggable
  @::mixin Flaggable::
  @::mixin Likeable::

  {Base,ObjectId,ObjectRef,secure,dash,daisy} = bongo
  {Relationship} = jraphical

  {log} = console

  @share()

  schema = _.extend {}, jraphical.Message.schema, {
    isLowQuality  : Boolean
    counts        :
      followers   :
        type      : Number
        default   : 0
      following   :
        type      : Number
        default   : 0
    originType  :
      type      : String
      required  : yes
    originId    :
      type      : ObjectId
      required  : yes
    deletedAt   : Date
    deletedBy   : ObjectRef
    meta        : require 'bongo/bundles/meta'
  }

  @set
    emitFollowingActivities: yes
    taggedContentRole : 'reply'
    tagRole           : 'tag'
    sharedMethods : JPost.sharedMethods
    schema        : schema
    relationships     :
      comment         : JComment
      participant     :
        targetType    : JAccount
        as            : ['author','commenter']
      likedBy         :
        targetType    : JAccount
        as            : 'like'
      repliesActivity :
        targetType    : CRepliesActivity
        as            : 'repliesActivity'
      tag             :
        targetType    : JTag
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : JAccount

  @getActivityType =-> COpinionActivity

  @getAuthorType =-> JAccount

  @getFlagRole =-> ['sender', 'recipient']

  createKodingError =(err)->
    kodingErr = new KodingError(err.message)
    for own prop of err
      kodingErr[prop] = err[prop]
    kodingErr

  @create = secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost.create.call @, client, codeSnip, callback

  delete: secure ({connection:{delegate}}, callback)->
    originId = @getAt 'originId'
    unless delegate.getId().equals originId
      callback new KodingError 'Access denied!'
    else
      id = @getId()
      {getDeleteHelper} = Relationship
      rel = null
      message = null

      queue = [
        ->
          Relationship.one {
            targetId    : id
            as          : "opinion"
          }, (err, rel_)->
            if err
              callback err
            else
              rel = rel_
              queue.next(err)
        ->
          rel.fetchSource (err, message_)->
            if err
              callback err
            else
              message = message_
              queue.next(err)
        ->
          message.removeReply rel, (err)-> queue.next(err)

        getDeleteHelper {
          targetId    : id
          sourceName  : /Activity$/
        }, 'source', (err)-> queue.next(err)

        getDeleteHelper {
          targetName  : {$ne : 'JAccount'}
          sourceId    : id
          sourceName  : 'JOpinion'
        }, 'target', (err)-> queue.next(err)

        ->
          Relationship.remove {
            targetId  : id
            as        : 'opinion'
          }, (err)-> queue.next(err)
        =>
          @emit "OpinionIsDeleted", yes
          queue.next()
        =>
          @remove()
          callback null
      ]
      daisy queue

  modify: secure (client, data, callback)->
    opinion =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, opinion, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback



class JDiscussion extends JPost

  @mixin Followable
  @::mixin Followable::
  @::mixin Taggable::
  @::mixin Notifying::
  @mixin Flaggable
  @::mixin Flaggable::
  @::mixin Likeable::

  {Base,ObjectId,ObjectRef,secure,dash,daisy} = bongo
  {Relationship} = jraphical

  {log} = console

  {once} = require 'underscore'

  @share()

  @getActivityType =-> CDiscussionActivity

  @getAuthorType =-> JAccount
  @getFlagRole =-> ['sender', 'recipient']
  @set
    emitFollowingActivities: yes
    taggedContentRole : 'post'
    tagRole           : 'tag'
    sharedMethods     :
      static          : ['create','on','one']
      instance        : [
        'on','reply','restComments','commentsByRange'
        'like','checkIfLikedBefore','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments'
        'updateTeaser'
      ]
    schema        : JPost.schema
    relationships     :
      opinion         :
        targetType    : JOpinion
        as            : 'opinion'
      participant     :
        targetType    : JAccount
        as            : ['author','commenter']
      likedBy         :
        targetType    : JAccount
        as            : 'like'
      repliesActivity :
        targetType    : CRepliesActivity
        as            : 'repliesActivity'
      tag             :
        targetType    : JTag
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : JAccount

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
    unless delegate instanceof JAccount
      callback new Error 'Log in required!'
    else
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
                log 'error adding content to delegate', err
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
                                      opinionData   : JSON.stringify comment
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
      .edges
        query         :
          sourceName  : 'JOpinion'
          targetName  : 'JComment'
          as          : 'reply'
          'data.deletedAt':
            $exists   : no
          'data.flags.isLowQuality':
            $ne       : yes
        # limit         : 3
        sort          :
          timestamp   : 1
      # .nodes()
      .and()
      .edges
        query         :
          targetName  : 'JTag'
          as          : 'tag'
        limit         : 5
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


class CDiscussionActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JDiscussion
        as          : 'discussion'

class COpinionActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JOpinion
        as          : 'opinion'

  # --------------------------------------------------------------------
  # This is what the CCommentActivity does - is not ready for use yet
  # --------------------------------------------------------------------
  # --arvid

  # {Relationship} = jraphical

  # @share()

  # @set
  #   encapsulatedBy  : CActivity
  #   schema          : CActivity.schema
  #   relationships   :
  #     subject       :
  #       targetType  : JOpinion
  #       as          : 'opinion'
  # @init = ->
  #   Relationship.on ['feed','*'], (relationships)=>
  #     relationships.forEach (relationship)=>
  #       if relationship.targetName is 'JOpinion' and relationship.as is 'opinion'
  #         activity = new COpinionActivity
  #         activity.save (err)->
  #           if err
  #             console.log "Couldn't save the activity", err
  #           else relationship.fetchSource (err, source)->
  #             if err
  #               console.log "Couldn't fetch the source", err
  #             else source.assureOpinionsActivity (err, repliesActivity)->
  #               if err
  #                 console.log err
  #               else activity.addSubject relationship, (err)->
  #                 if err
  #                   console.log err
  #                 else repliesActivity.addSubject relationship, (err)->
  #                   if err
  #                     console.log err
  #                   else source.fetchParticipants? (err, participants)->
  #                     if err
  #                       console.log "Couldn't fetch the participants", err
  #                     else relationship.fetchTarget (err, target)->
  #                       if err
  #                         console.log "Couldn't fetch the target", err
  #                       else participants.forEach (participant)->
  #                         participant.assureActivity repliesActivity, (err)->
  #                           if err
  #                             console.log err
  #                           else unless participant.getId().equals target.originId
  #                             participant.addActivity activity,
  #                               if participant.getId().equals source.originId
  #                                 'author'
  #                               else
  #                                 'commenter'
  #                             , (err)->
  #                               if err
  #                                 console.log "Couldn't add an activity", err
  # @init()
