JAccount  = require '../models/account'

module.exports = class Likeable

  {ObjectRef,daisy,secure} = require 'bongo'
  {Relationship} = require 'jraphical'
  {permit} = require '../models/group/permissionset'

  checkIfLikedBefore: secure ({connection}, callback)->
    {delegate}    = connection
    {constructor} = @

    if not delegate
      callback null, no
    else
      Relationship.one
        sourceId : @getId()
        targetId : delegate.getId()
        as       : 'like'
      , (err, likedBy)->
        if likedBy then callback null, yes else callback err, no

  like: permit 'like posts',
    success:({connection, context}, callback)->

      {group}       = context
      {delegate}    = connection
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
              # adding group to data field because on group based queries,
              # we need group slug, (see activityticker.coffee)
              options =
                respondWithCount : yes
                data             : if group then {group}

              @addLikedBy delegate, options, (err, docs, count)=>
                if err
                  callback err
                else
                  @update ($set: 'meta.likes': count), callback
                  delegate.update ($inc: 'counts.likes': 1), (err)->
                    console.log err if err
                  @fetchOrigin? (err, origin)=>
                    if err then console.log "Couldn't fetch the origin"
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

            else
              @removeLikedBy delegate, respondWithCount: yes, (err, count)=>
                if err
                  callback err
                  console.log err
                else
                  @update ($set: 'meta.likes': count), callback
                  delegate.update ($inc: 'counts.likes': -1), (err)=>
                    console.log err if err
                    @fetchOrigin? (err, origin)=>
                      if err then log "Couldn't fetch the origin"
                      else @emit 'LikeIsRemoved',
                        origin
                        subject : @
                        liker   : delegate
