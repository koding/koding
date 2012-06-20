console.log 12345, process.pid

class JPost extends jraphical.Message
  
  @::mixin Taggable::
  
  {secure,dash,daisy} = bongo
  {Relationship} = jraphical
  
  # TODO: these relationships may not be abstract enough to belong to JPost.
  @set
    tagRole           : 'post'
    sharedMethods     :
      static          : ['create','on','one']
      instance        : [
        'on','reply','restComments','commentsByRange'
        'like','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify'
      ]
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

  @getAuthorType =-> JAccount

  @getActivityType =-> CActivity
  
  createKodingError =(err)->
    kodingErr = new KodingError(err.message)
    for own prop of err
      kodingErr[prop] = err[prop]
    kodingErr
  
  @create = secure (client, data, callback)->
    constructor = @
    {connection:{delegate}} = client
    unless delegate instanceof constructor.getAuthorType() # TODO: rethink/improve
      callback new Error 'Access denied!'
    else
      if data?.meta?.tags
        {tags} = data.meta
        delete data.meta.tags
      status = new constructor data
      # TODO: emit an event, and move this (maybe)
      activity = new (constructor.getActivityType())
      activity.originId = delegate.getId()
      activity.originType = delegate.constructor.name
      teaser = null
      queue = [
        ->
          status
            .sign(delegate)
            .save (err)->
              if err
                callback err
              else queue.next()
        ->
          activity.save (err)->
            if err
              callback createKodingError err
            else queue.next()
        ->
          activity.addSubject status, (err)->
            if err
              callback createKodingError err
            else queue.next()
        ->
          if tags?.length
            status.addTags client, tags, (err)->
              if err
                callback createKodingError err
              else
                queue.next()
          else queue.next()
        ->
          status.fetchTeaser (err, teaser_)=>
            if err
              callback createKodingError err
            else
              teaser = teaser_
              queue.next()
        ->
          activity.update
            $set:
              snapshot: JSON.stringify(teaser)
            $addToSet:
              snapshotIds: status.getId()
          , ->
            callback null, teaser
            queue.next()
        -> 
          status.addParticipant delegate, 'author'
      ]
      daisy queue

  modify: secure ({connection:{delegate}}, formData, callback)->
    if delegate.getId().equals @originId
      @update formData, (err, response)=> callback err, response
    else
      callback new KodingError "Access denied"

  mark: secure ({connection:{delegate}}, flag, callback)->
    @flag flag, yes, delegate.getId(), ['sender', 'recipient'], callback
    
  unmark: secure ({connection:{delegate}}, flag, callback)->
    @unflag flag, delegate.getId(), ['sender', 'recipient'], callback

  delete: secure ({connection:{delegate}}, callback)->
    originId = @getAt 'originId'
    unless delegate.getId().equals originId
      callback new KodingError 'Access denied!'
    else
      id = @getId()
      {getDeleteHelper} = Relationship
      queue = [
        getDeleteHelper {
          targetId    : id
          sourceName  : /Activity$/
        }, 'source', -> queue.fin()
        getDeleteHelper {
          sourceId    : id
          sourceName  : 'JComment'
        }, 'target', -> queue.fin()
        ->
          Relationship.remove {
            targetId  : id
            as        : 'post'
          }, -> queue.fin()
        => @remove -> queue.fin()
      ]
      dash queue, =>
        @emit 'PostIsDeleted', 1
        callback null
  
  removeReply:(rel, callback)->
    id = @getId()
    teaser = null
    activityId = null
    queue = [
      ->
        Relationship.one {
          targetId    : id
          sourceName  : /Activity$/
        }, (err, rel)->
          if err
            queue.next err
          else
            activityId = rel.getAt 'sourceId'
            queue.next()
      ->
        rel.update $set: 'data.deletedAt': new Date, -> queue.next()
      =>
        @update $inc: repliesCount: -1, -> queue.next()
      =>
        @fetchTeaser (err, teaser_)=>
          if err
            callback createKodingError err
          else
            teaser = teaser_
            queue.next()
      ->
        CActivity.update _id: activityId, {
          $set      : {snapshot: JSON.stringify teaser}
          $pullAll  : {snapshotIds: rel.getAt 'targetId'}
        }, -> queue.next()
      
      callback
    ]
    daisy queue
  
  like: secure ({connection}, callback)->
    {delegate} = connection
    {constructor} = @
    unless delegate instanceof constructor.getAuthorType()
      callback new Error 'Only instances of JAccount can like things.'
    else
      Relationship.one
        sourceId: @getId()
        targetId: delegate.getId()
        as: 'like'
      , (err, likedBy)=>
        if err
          callback err
        else
          unless likedBy
            @addLikedBy delegate, returnCount: yes, (err, count)=>
              if err
                callback err
              else
                @update ($set: 'meta.likes': count), callback
          else
            callback new Error 'You already liked this.'
  
  reply: secure ({connection}, replyType, comment, callback)->
    {delegate} = connection
    unless delegate instanceof JAccount
      callback new Error 'Log in required!'
    else
      comment = new JComment body: comment
      comment
        .sign(delegate)
        .save (err)=>
          if err
            callback err
          else
            @addComment comment, returnCount: yes, (err, count)=>
              if err
                callback err
              else
                @update $inc: repliesCount: 1, (err)=>
                  if err
                    callback err
                  else
                    callback null, comment
                    @addParticipant delegate, 'commenter', (err)-> #TODO: what should we do with this error?

  # TODO: the following is not well-factored.  It is not abstract enough to belong to "Post".
  # for the sake of expedience, I'll leave it as-is for the time being.
  fetchTeaser:(callback)->
    @beginGraphlet()
      .edges
        query         :
          targetName  : 'JComment'
          as          : 'reply'
          'data.deletedAt':
            $exists   : no
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
    queryOptions.sort = timestamp: -1
    @fetchComments selector, queryOptions, callback

  restComments:(skipCount, callback)->
    [callback, skipCount] = [skipCount, callback] unless callback
    skipCount ?= 3
    @fetchComments {},
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
    @beginGraphlet()
      .edges
        query         :
          targetName  :'JComment'
        sort          :
          timestamp   : 1
      .nodes()
    .endGraphlet()
    .fetchRoot callback
  
  save:->
    delete @data.replies #TODO: this hack should not be necessary...  but it is for some reason.
    # in any case, it should be resolved permanently once we implement Model#prune
    super
