{Model, Base, ObjectId, secure} = require 'bongo'

module.exports = class JEmailNotificationGG extends Model

  @set
    indexes          :
      event          : 'sparse'
      sender         : 'sparse'
      receiver       : 'sparse'
      contentId      : 'sparse'
    schema           :
      dateIssued     :
        type         : Date
        default      : -> new Date
      dateAttempted  : Date
      event          : String
      receiver       : ObjectId
      sender         : ObjectId
      contentId      : ObjectId
      activity       : Object
      priority       :
        type         : String
        default      : 'instant'
        enum         : ['Invalid priority',['instant','daily']]
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status',['queued','attempted','postponed']]

  @commonActivities  = ['JCodeSnip', 'JStatusUpdate', 'JDiscussion',
                        'JOpinion', 'JCodeShare', 'JLink', 'JTutorial']
  flags =
    comment           :
      eventType       : 'ReplyIsAdded'
      contentTypes    : @commonActivities
    likeActivities    :
      eventType       : 'LikeIsAdded'
      contentTypes    : @commonActivities
    likeComments      :
      eventType       : 'LikeIsAdded'
      contentTypes    : ['JComment']
    followActions     :
      eventType       : ''
      contentTypes    : []
    privateMessage    :
      eventType       : 'ReplyIsAdded'
      contentTypes    : ['JPrivateMessage']

  @checkEmailChoice = (options, callback)->

    {username, contentType, event} = options

    JUser = require './user'
    JUser.someData {username}, {email:1, emailFrequency:1}, (err, cursor)->
      if err
        console.error "Could not load user record for #{username}"
        callback err
      else cursor.nextObject (err, user)->
        {emailFrequency, email} = user
        unless emailFrequency?
          callback null
        else
          if emailFrequency.global is 'instant'
            for key, type of flags
              if contentType in type.contentTypes and event is type.eventType
                if emailFrequency[key]
                  state = emailFrequency[key]
                  callback null, state, email, key
                  return
          callback null

  @create = (data, callback=->)->

    {actor, receiver, event, contents} = data

    username = receiver.getAt 'profile.nickname'
    sender   = actor.id
    receiver = receiver._id

    activity =
      subject    : contents.subject
      actionType : contents.actionType
      content    : contents[contents.actionType]

    # console.log "SENDER  :", sender
    # console.log "EVENT   :", event
    # console.log "RECEIVER:", receiver
    # console.log "ACTIVITY:", activity

    contentType = contents.subject.constructorName
    contentId   = if activity.content then \
                     activity.content.id else contents.subject.id

    @checkEmailChoice {username, event, contentType}, (err, state)->
      if err or state not in ['daily', 'instant']
        console.log "User disabled e-mail notifications."
        callback? err
      else
        # console.log "STATE:", state

        JEmailNotificationGG.count {event, sender, receiver, contentId}, \
        (err, count)->
          if not err and count is 0
            notification = new JEmailNotificationGG {
              event, sender, receiver, contentId, activity, priority: state
            }
            notification.save (err)->
              if err then console.error err
              else console.log "Saved to queue."
          else
            console.log "Already exists"
