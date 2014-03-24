{Model, Base, ObjectId, secure, signature} = require 'bongo'
{extend} = require 'underscore'
KodingError = require '../error'

{ v4: createId } = require 'node-uuid'

# Poor mans unique ID generator
getUniqueId = createId

module.exports = class JMailNotification extends Model

  @share()

  @set
    indexes          :
      event          : 'sparse'
      sender         : 'sparse'
      receiver       : 'sparse'
      contentId      : 'sparse'
    sharedMethods    :
      static         :
        unsubscribeWithId:
          (signature String, String, String, Function)
    sharedEvents     :
      static         : []
      instance       : []
    schema           :
      dateIssued     :
        type         : Date
        default      : -> new Date
      dateAttempted  : Date
      event          : String
      eventFlag      : String
      unsubscribeId  : String
      senderEmail    : String
      receiver       : ObjectId
      sender         : ObjectId
      contentId      : ObjectId
      activity       : Object
      bcc            : String
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status', ['queued', 'attempted',
                                           'sending', 'postponed']]

  @commonActivities  = ['JNewStatusUpdate', 'JComment']

  flags =
    comment              :
      eventType          : ['ReplyIsAdded']
      contentTypes       : @commonActivities
      definition         : 'about comments'
    likeActivities       :
      eventType          : ['LikeIsAdded']
      contentTypes       : @commonActivities
      definition         : 'about likes'
    followActions        :
      eventType          : ['FollowHappened']
      contentTypes       : ['JAccount']
      definition         : 'about follows'
    privateMessage       :
      eventType          : ['ReplyIsAdded', 'PrivateMessageSent']
      contentTypes       : ['JPrivateMessage']
      definition         : 'about private messages'
    groupInvite          :
      eventType          : ['Invited']
      contentTypes       : ['JGroup'],
      definition         : "when someone invites you to their group"
    groupRequest         :
      eventType          : ['ApprovalRequested', 'InvitationRequested']
      contentTypes       : ['JGroup'],
      definition         : "when someone requests membership to group"
    groupApproved        :
      eventType          : ['Approved']
      contentTypes       : ['JGroup'],
      definition         : "when user's group membership has been approved"
    groupJoined          :
      eventType          : ['GroupJoined']
      contentTypes       : ['JGroup'],
      definition         : "when a member joins your group"
    groupLeft            :
      eventType          : ['GroupLeft']
      contentTypes       : ['JGroup'],
      definition         : "when a member leaves your group"

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
          if emailFrequency.global is true
            for key, type of flags
              if contentType in type.contentTypes and event in type.eventType
                if emailFrequency[key]
                  state = emailFrequency[key]
                  callback null, state, key, email
                  return
          callback null

  @create = (data, callback=->)->

    {actor, receiver, event, contents, bcc} = data

    return callback null  if receiver.type is 'unregistered'

    username = receiver.getAt 'profile.nickname'
    sender   = actor._id ? actor.id ? actor
    receiver = receiver._id

    activity =
      subject    : contents.subject
      actionType : contents.actionType
      content    : contents[contents.actionType]

    activity.message = contents.message  if contents.message

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

    selector = {event, receiver, contentId}
    if sender instanceof ObjectId
    then selector.sender = sender
    else selector.senderEmail = sender

    JMailNotification.count selector, (err, count)->
      if not err and count is 0
        notification = new JMailNotification extend selector, {
          eventFlag, activity, unsubscribeId: getUniqueId()+getUniqueId()+'', bcc
        }
        # console.log "OK good to go."
        notification.save (err)->
          if err then console.error err
          else
            callback null
          # else console.log "Saved to queue."
      # else
      #   console.log "Already exists"

  @unsubscribeWithId = (unsubscribeId, email, opt, callback)->

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
              prefs.global = false
            else if opt is 'daily'
              prefs.daily = false
            else
              prefs[notification.eventFlag] = false
              {definition} = flags[notification.eventFlag]
            username = account.profile.nickname
            JUser = require './user'
            JUser.one {username}, (err, user)->
              if err or not user then callback err
              else if user.email isnt email
                callback new KodingError 'Unsubscribe token does not match given email.'
              else account.setEmailPreferences user, prefs, (err)->
                if err then callback err
                else
                  callback null, "You will no longer get e-mails #{definition}"
