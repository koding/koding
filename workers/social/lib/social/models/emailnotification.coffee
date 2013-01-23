{Model, Base, ObjectId, secure} = require 'bongo'

# Poor mans unique ID generator
getUniqueId=->
  r = Math.floor Math.random()*9000000+1
  "#{r}#{Date.now()}"

module.exports = class JEmailNotificationGG extends Model

  @share()

  @set
    indexes          :
      event          : 'sparse'
      sender         : 'sparse'
      receiver       : 'sparse'
      contentId      : 'sparse'
    sharedMethods    :
      static         : ['unsubscribeWithId']
    schema           :
      dateIssued     :
        type         : Date
        default      : -> new Date
      dateAttempted  : Date
      event          : String
      eventFlag      : String
      unsubscribeId  : String
      receiver       : ObjectId
      sender         : ObjectId
      contentId      : ObjectId
      activity       : Object
      priority       :
        type         : String
        default      : 'instant'
        enum         : ['Invalid priority', ['instant','daily']]
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status', ['queued','attempted','postponed']]

  @commonActivities  = ['JCodeSnip', 'JStatusUpdate', 'JDiscussion', 'JLink',
                        'JOpinion', 'JCodeShare', 'JComment', 'JTutorial',
                        'JReview']
  flags =
    comment          :
      eventType      : ['ReplyIsAdded']
      contentTypes   : @commonActivities
      definition     : 'about comments'
    likeActivities   :
      eventType      : ['LikeIsAdded']
      contentTypes   : @commonActivities
      definition     : 'about activity likes'
    followActions    :
      eventType      : ['FollowHappened']
      contentTypes   : ['JAccount']
      definition     : 'about following changes'
    privateMessage   :
      eventType      : ['ReplyIsAdded', 'PrivateMessageSent']
      contentTypes   : ['JPrivateMessage']
      definition     : 'about private messages'

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
              if contentType in type.contentTypes and event in type.eventType
                if emailFrequency[key]
                  state = emailFrequency[key]
                  callback null, state, key, email
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

    if event is 'FollowHappened'
      contentType = 'JAccount'
      contentId   = receiver
    else
      contentType = contents.subject.constructorName
      contentId   = if activity.content then \
                       activity.content.id else contents.subject.id

    @checkEmailChoice {username, event, contentType}, (err, state, key)->
      if err or state not in ['daily', 'instant']
        # console.log "User disabled e-mail notifications."
        callback? err
      else
        # console.log "STATE:", state

        JEmailNotificationGG.count {event, sender, receiver, contentId}, \
        (err, count)->
          if not err and count is 0
            notification = new JEmailNotificationGG {
              event, sender, receiver, contentId, activity,
              eventFlag: key, priority: state, unsubscribeId: getUniqueId()
            }
            # console.log "OK good to go."
            notification.save (err)->
              if err then console.error err
              # else console.log "Saved to queue."
          # else
          #   console.log "Already exists"

  @unsubscribeWithId = (unsubscribeId, all, callback)->

    JEmailNotificationGG.one {unsubscribeId}, (err, notification)->
      if err or not notification then callback err
      else
        JAccount = require './account'
        JAccount.one {_id: notification.receiver}, (err, account)->
          if err or not account then callback err
          else
            prefs = {}
            definition = ''
            if all is 'all'
              prefs.global  = 'never'
            else
              prefs[notification.eventFlag] = 'never'
              {definition} = flags[notification.eventFlag]
            username = account.profile.nickname
            JUser = require './user'
            JUser.one {username}, (err, user)->
              if err or not user then callback err
              else account.setEmailPreferences user, prefs, (err)->
                if err then callback err
                else
                  callback null, "You will no longer get e-mails #{definition}"
