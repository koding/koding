{Model, Base, ObjectId, secure} = require 'bongo'

module.exports = class JEmail extends Model

  Emailer      = require '../emailer'
  KodingError  = require '../error'
  JAccount     = require './account'

  @set
    indexes          :
      event          : 'sparse'
      originId       : 'sparse'
      activityId     : 'sparse'
    schema           :
      dateQueued     :
        type         : Date
        default      : -> new Date
      dateSent       : Date
      email          : String
      emailFrequency : Object
      header         : String
      body           : String
      event          :
        type         : String
        default      : 'CustomEvent'
      originId       : ObjectId
      activityId     : ObjectId
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status',['queued','attempted']]

  commonActivities = ['JCodeSnip', 'JStatusUpdate', 'JDiscussion',
                      'JOpinion', 'JCodeShare', 'JLink', 'JTutorial']
  commonHeader     = (m)-> """[Koding Bot] A new notification"""
  commonTemplate   = (m)->

    action  = ''
    preview = ''
    switch m.event
      when 'LikeIsAdded'
        action = "liked your"
      when 'ReplyIsAdded'
        action  = "commented on your"
        preview = """

                    <hr/>
                      #{m.realContent.body}
                    <hr/>

                  """

    """
      Hi #{m.receiver.profile.firstName},

      <a href="https://koding.com/#{m.sender.profile.nickname}">#{m.sender.profile.firstName} #{m.sender.profile.lastName}</a> #{action} #{m.contentLink}.
      #{preview}
      --
      Lonely Koding Bot.
    """

  flags =
    comment           :
      eventType       : 'ReplyIsAdded'
      contentTypes    : commonActivities
      header          : commonHeader
      instantTemplate : commonTemplate
    likeActivities    :
      eventType       : 'LikeIsAdded'
      contentTypes    : commonActivities
      header          : commonHeader
      instantTemplate : commonTemplate
    likeComments      :
      eventType       : 'LikeIsAdded'
      contentTypes    : ['JComment']
      header          : commonHeader
      instantTemplate : commonTemplate
    followActions     :
      eventType       : ''
      contentTypes    : []
      header          : commonHeader
      instantTemplate : commonTemplate
    privateMessage    :
      eventType       : 'ReplyIsAdded'
      contentTypes    : ['JPrivateMessage']
      header          : commonHeader
      instantTemplate : (m)-> """
        Hi #{m.receiver.profile.firstName},

        #{m.sender.profile.firstName} #{m.sender.profile.lastName} sent you a <a href="https://koding.com/Inbox">private message</a>.

        --
        Lonely Koding Bot.
      """

  @checkEmailChoice = (options, callback)->

    {username, contentType, event} = options

    JUser = require './user'
    JUser.someData {username}, {email: 1, emailFrequency: 1}, (err, cursor)->
      if err
        console.error "Could not load user record for #{username}"
        callback err, {state: no}
      else cursor.nextObject (err, user)->
        {emailFrequency, email} = user
        unless emailFrequency?
          callback null, {state: no}
        else
          if emailFrequency.global is 'instant'
            for key, type of flags
              if contentType in type.contentTypes and event is type.eventType
                if emailFrequency[key]
                  callback null, {state: emailFrequency[key] in ['instant', 'daily'],
                                  email, type}
                  return
          callback null, {state: no}

  @createNotificationEmail = (data, callback=->)->

    {actor, receiver, event, contents} = data

    username    = receiver.getAt('profile.nickname')
    contentType = contents.subject.constructorName

    # console.log "HERE", data

    createEmail  = (details, callback)->
      body       = details.notification.type.instantTemplate details
      header     = details.notification.type.header details
      {event}    = details.notification.type
      {email}    = details.notification
      originId   = details.sender._id
      activityId = details.realContent._id

      # console.log body

      JEmail.count {event, activityId, originId}, (err, count)=>
        if not err and count is 0
          notification = new JEmail {
            event, email, header, body, activityId, originId
          }
          notification.save (err)->
            if err then console.error err
            else console.log "Saved to queue."
        else
          console.log "Already exists"

    fetchSubjectContent = (contents, callback)->
      {constructorName} = contents.subject
      constructor       = Base.constructors[constructorName]
      constructor.one {_id:contents.subject.id}, (err, res)->
        if err then console.error err
        callback err, res

    fetchContent = (contents, callback)->
      {constructorName} = contents[contents.actionType]
      unless constructorName
        callback new KodingError 'Action type wrong.'
      else
        constructor     = Base.constructors[constructorName]
        {id}            = contents[contents.actionType]
        constructor.one {_id:id}, (err, res)->
          if err then console.error err
          callback err, res

    fetchSubjectContentLink = (content, type, callback)->

      contentTypeLinkMap = (link)->
        pre = "<a href='https://koding.com/Activity/#{link}'>"

        JReview           : "#{pre}review</a>"
        JComment          : "#{pre}comment</a>"
        JOpinion          : "#{pre}opinion</a>"
        JCodeSnip         : "#{pre}code snippet</a>"
        JTutorial         : "#{pre}tutorial</a>"
        JDiscussion       : "#{pre}discussion</a>"
        JLinkActivity     : "#{pre}link</a>"
        JStatusUpdate     : "#{pre}status update</a>"
        JPrivateMessage   : "#{pre}private message</a>"
        JQuestionActivity : "#{pre}question</a>"

      if content.slug
        callback null, contentTypeLinkMap(content.slug)[type]
      else
        {constructorName} = content.bongo_
        constructor = Base.constructors[constructorName]
        constructor.fetchRelated? content._id, (err, relatedContent)->
          if err then callback err
          else
            unless relatedContent.slug?
              constructor = \
                Base.constructors[relatedContent.bongo_.constructorName]
              constructor.fetchRelated? relatedContent._id, (err, content)->
                if err then callback err
                else
                  callback null, contentTypeLinkMap(content.slug)[type]
            else
              callback null, contentTypeLinkMap(relatedContent.slug)[type]

    @checkEmailChoice {username, event, contentType}, \
    (err, notification)->
      if err or notification.state is no
        console.log "User disabled e-mail notifications."
        callback? err
      else
        JAccount.one {_id:actor.id}, (err, sender)->
          if err then callback err
          else
            fetchSubjectContent contents, (err, subjectContent)->
              if err then callback err
              else
                realContent = subjectContent
                details = {sender, receiver, event, notification, \
                           subjectContent, realContent}
                fetchSubjectContentLink subjectContent, contentType, \
                (err, link)->
                  if err then callback err
                  else
                    details.contentLink = link
                    if event is 'ReplyIsAdded'
                      fetchContent contents, (err, content)->
                        if err then callback err
                        else
                          details.realContent = content
                          createEmail details
                    else
                      createEmail details
