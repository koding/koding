class JOpinion extends JPost
  @mixin Followable
  @::mixin Followable::
  @::mixin Taggable::
  @::mixin Notifying::
  @mixin Flaggable
  @::mixin Flaggable::

  {Base,ObjectId,ObjectRef,secure,dash,daisy} = bongo
  {Relationship} = jraphical

  {log} = console

  @share()

  @set
    emitFollowingActivities: yes
    taggedContentRole : 'reply'
    tagRole           : 'tag'
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
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

  # ?<
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

  modify: secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, codeSnip, callback

  #?>

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback



class JDiscussion extends JPost

  @mixin Followable
  @::mixin Followable::
  @::mixin Taggable::
  @::mixin Notifying::
  @mixin Flaggable
  @::mixin Flaggable::

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
    sharedMethods : JPost.sharedMethods
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
                              $set: 'sorts.repliesCount': count
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
                                  actionType    : 'reply'
                                  replier       : ObjectRef(delegate).data
                                  reply         : ObjectRef(comment).data
                                  repliesCount  : count
                                  relationship  : docs[0]
                                }
                              @follow client, emitActivity: no, (err)->
                              @addParticipant delegate, 'commenter', (err)-> #TODO: what should we do with this error?

  fetchTeaser:(callback)->
    @beginGraphlet()
      .edges
        query         :
          targetName  : 'JOpinion'
          as          : 'reply'
          'data.deletedAt':
            $exists   : no
          'data.flags.isLowQuality':
            $ne       : yes
        limit         : 3
        sort          :
          timestamp   : -1
      .reverse()
      .and()
      .edges
        query         :
          targetName  : 'JTag'
          as          : 'tag'
        limit         : 5
      .nodes()
    .endGraphlet()
    .fetchRoot callback
    #log "discussion teaser was fetched for ", @data.title

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
    queryOptions.sort = timestamp: -1
    console.log queryOptions
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
    log "discussion fetching entire message"
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