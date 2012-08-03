class JComment extends jraphical.Reply
  
  {ObjectId,ObjectRef,dash,daisy} = require 'bongo'
  {Relationship}  = require 'jraphical'
  
  @share()

  @set
    sharedMethods :
      instance    : ['delete']
    schema        :
      isLowQuality: Boolean
      body        :
        type      : String
        required  : yes
      originType  :
        type      : String
        required  : yes
      originId    :
        type      : ObjectId
        required  : yes
      deletedAt   : Date
      deletedBy   : ObjectRef
      meta        : require 'bongo/bundles/meta'
  
  delete: bongo.secure (client, callback)->
    {delegate} = client.connection
    {getDeleteHelper} = Relationship
    id = @getId()
    comment = @
    queue = [
      ->
        Relationship.one {
          targetId  : id
          as        : 'reply'
        }, (err, rel)->
          if err
            queue.fin err
          else
            rel.fetchSource (err, message)->
              if err
                queue.fin err
              else if delegate.can 'delete', comment
                message.removeReply rel, -> queue.fin()
              else
                callback new KodingError 'Access denied!'
      =>
        deleter = ObjectRef(delegate)
        @update
          $unset      :
            body      : 1
          $set        :
            deletedAt : new Date
            deletedBy : deleter
        , -> queue.fin()
    ]
    dash queue, callback

class CCommentActivity extends CActivity
  
  {Relationship} = jraphical
  
  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : jraphical.Relationship
        as          : 'comment'
  @init = ->
    Relationship.on ['feed','*'], (relationships)=>
      relationships.forEach (relationship)=>
        if relationship.targetName is 'JComment' and relationship.as is 'reply'
          activity = new CCommentActivity
          activity.save (err)->
            if err
              console.log "Couldn't save the activity", err
            else relationship.fetchSource (err, source)->
              if err
                console.log "Couldn't fetch the source", err
              else source.assureRepliesActivity (err, repliesActivity)->
                if err
                  console.log err
                else activity.addSubject relationship, (err)->
                  if err
                    console.log err
                  else repliesActivity.addSubject relationship, (err)->
                    if err
                      console.log err
                    else source.fetchParticipants? (err, participants)->
                      if err
                        console.log "Couldn't fetch the participants", err
                      else relationship.fetchTarget (err, target)->
                        if err
                          console.log "Couldn't fetch the target", err
                        else participants.forEach (participant)->
                          participant.assureActivity repliesActivity, (err)->
                            if err
                              console.log err
                            else unless participant.getId().equals target.originId
                              participant.addActivity activity,
                                if participant.getId().equals source.originId
                                  'author'
                                else
                                  'commenter'
                              , (err)->
                                if err
                                  console.log "Couldn't add an activity", err 
  @init()
