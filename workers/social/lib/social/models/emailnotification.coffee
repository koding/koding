{Model, Base, ObjectId, secure} = require 'bongo'

# Poor mans unique ID generator
getUniqueId=->
  r = Math.floor Math.random()*9000000+1
  "#{r}#{Date.now()}"

module.exports = class JMailNotification extends Model

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
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status', ['queued', 'attempted',
                                           'sending', 'postponed']]

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
      definition     : 'about likes'
    followActions    :
      eventType      : ['FollowHappened']
      contentTypes   : ['JAccount']
      definition     : 'about follows'
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
          if emailFrequency.global is 'on'
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

    # I know that looks sucks. ~ GG
    # Its walking on notification flags and tries to find correct eventFlag
    eventFlag = [[key, type] for key, type of flags                \
                             when contentType in type.contentTypes \
                             and event in type.eventType][0][0]?[0]

    JMailNotification.count {event, sender, receiver, contentId}, \
    (err, count)->
      if not err and count is 0
        notification = new JMailNotification {
          event, sender, receiver, eventFlag, contentId, activity, \
          unsubscribeId: getUniqueId()+getUniqueId()+''
        }
        # console.log "OK good to go."
        notification.save (err)->
          if err then console.error err
          # else console.log "Saved to queue."
      # else
      #   console.log "Already exists"

  @unsubscribeWithId = (unsubscribeId, opt, callback)->

    JMailNotification.one {unsubscribeId}, (err, notification)->
      if err or not notification then callback err
      else
        JAccount = require './account'
        JAccount.one {_id: notification.receiver}, (err, account)->
          if err or not account then callback err
          else
            prefs = {}
            definition = ''
            if opt is 'all'
              prefs.global = 'off'
            else if opt is 'daily'
              prefs.daily = 'off'
            else
              prefs[notification.eventFlag] = 'off'
              {definition} = flags[notification.eventFlag]
            username = account.profile.nickname
            JUser = require './user'
            JUser.one {username}, (err, user)->
              if err or not user then callback err
              else account.setEmailPreferences user, prefs, (err)->
                if err then callback err
                else
                  callback null, "You will no longer get e-mails #{definition}"
