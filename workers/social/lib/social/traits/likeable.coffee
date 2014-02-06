JAccount  = require '../models/account'
CActivity = require '../models/activity'

module.exports = class Likeable

  {ObjectRef,daisy,secure} = require 'bongo'
  {Relationship} = require 'jraphical'
  {permit} = require '../models/group/permissionset'

  checkIfLikedBefore: secure ({connection}, callback)->
    {delegate} = connection
    {constructor} = @
    if not delegate
      callback null, no
    else
      Relationship.one
        sourceId: @getId()
        targetId: delegate.getId()
        as: 'like'
      , (err, likedBy)=>
        if likedBy
          callback null, yes
        else
          callback err, no

  like: permit 'like posts',
    success:({connection, context}, callback)->

      {group} = context
      {delegate} = connection
      {constructor} = @
      unless delegate instanceof JAccount
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
              @addLikedBy delegate, respondWithCount: yes, (err, docs, count)=>
                if err
                  callback err
                else
                  @update ($set: 'meta.likes': count), callback
                  if constructor.name in ["JComment", "JOpinion"]
                    constructor.fetchRelated? @getId(), (err, activity)->
                      activity.triggerCache(constructor.name == "JComment")
                  delegate.update ($inc: 'counts.likes': 1), (err)->
                    console.log err if err
                  @fetchActivityId? (err, id)->
                    CActivity.update {_id: id}, {
                      $set: 'sorts.likesCount': count
                    }, ->
                  @fetchOrigin? (err, origin)=>
                    if err then log "Couldn't fetch the origin"
                    else @emit 'LikeIsAdded', {
                      origin
                      subject       : ObjectRef(@).data
                      actorType     : 'liker'
                      actionType    : 'like'
                      liker         : ObjectRef(delegate).data
                      likesCount    : count
                      relationship  : docs[0]
                      group
                    }

                  @flushOriginSnapshot constructor
            else
              @removeLikedBy delegate, respondWithCount: yes, (err, count)=>
                if err
                  callback err
                  console.log err
                else
                  @update ($set: 'meta.likes': count), callback
                  delegate.update ($inc: 'counts.likes': -1), (err)->
                    console.log err if err
                  @flushOriginSnapshot constructor

  flushOriginSnapshot:(constructor)->
    if constructor.name is 'JComment'
      Relationship.one
        targetId: @getId()
        as: 'reply'
      , (err, rel)->
        if not err and rel
          rel.fetchSource (err, source)->
            if not err and source
              source.flushSnapshot?()
