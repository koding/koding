class JOpinion extends JPost

  {Base,ObjectRef,secure,dash,daisy} = bongo
  {Relationship} = jraphical
  {log} = console

  {once} = require 'underscore'

  @share()

  @getActivityType =-> COpinionActivity

  @getAuthorType =-> JAccount

  @set
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
  @create = secure (client, data, callback)->
    log "creating opinion"
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost.create.call @, client, codeSnip, callback
    log "done creating opinion"

  modify: secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, codeSnip, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback



class JDiscussion extends JPost

  # broken : tag support
  {Base,ObjectRef,secure,dash,daisy} = bongo
  {Relationship} = jraphical
  {log} = console

  {once} = require 'underscore'

  @share()

  @getActivityType =-> CDiscussionActivity

  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    relationships     :
      opinion         : JOpinion
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
  #  JPost::reply.call @, client, JOpinion, comment, callback
    {delegate} = client.connection
    unless delegate instanceof JAccount
      callback new Error 'Log in required!'
    else
      log "opinion to be posted:", comment
      comment = new JOpinion
        body: comment
        title: comment
      log "it is now:",comment
      exempt = delegate.checkFlag('exempt')
      if exempt
        comment.isLowQuality = yes
      comment
        .sign(delegate)
        .save (err)=>
          if err
            callback err
          else
            delegate.addContent comment, (err)-> console.log 'error adding content to delegate', err
            @addOpinion comment,
              flags:
                isLowQuality    : exempt
            , (err, docs)=>
              log "docs", docs
              if err
                callback err
              else
                log "opinion added!"
                if exempt
                  callback null, comment
                else
                  Relationship.count {
                    sourceId                    : @getId()
                    as                          : 'reply'
                    'data.flags.isLowQuality'   : $ne: yes
                  }, (err, count)=>
                    if err
                      callback err
                    else
                      log "relationship count", count
                      @update $set: repliesCount: count, (err)=>
                        if err
                          callback err
                        else
                          callback null, comment
                          @fetchActivityId (err, id)->
                            log "activity id", id
                            CActivity.update {_id: id}, {
                              $set: 'sorts.repliesCount': count
                            }, log
                          @fetchOrigin (err, origin)=>
                            if err
                              console.log "Couldn't fetch the origin"
                            else
                              log "origin", origin
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
                              log "looks like we've completed the whole reply thing"

  fetchTeaser:(callback)->
    log "fetching teaser"
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
    log "teaser was fetched", @

  fetchRelativeComments:({limit, before, after}, callback)->
    log "fetching relative comments"
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
    log "fetching comments by range"
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
    log "fetching restcomments"
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
        callback err
      else
        # comments.reverse()
        callback null, comments

  fetchEntireMessage:(callback)->
    log "fetching entire message"
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
        as          : 'content'

class COpinionActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JOpinion
        as          : 'content'