jraphical = require 'jraphical'

CActivity = require '../../activity'

module.exports = class CCommentActivity extends CActivity
  
  {Relationship} = jraphical

  @trait __dirname, '../../../traits/grouprelated'

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
