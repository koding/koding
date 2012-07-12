class NotificationController extends KDObject

  subjectMap = ->

    JStatusUpdate       : "status"
    JCodeSnip           : "code snippet"
    JQuestionActivity   : "question"
    JDiscussionActivity : "discussion"
    JLinkActivity       : "link"
    JPrivateMessage     : "private message"

  constructor:->

    super

    @getSingleton('mainController').on "AccountChanged", (account)=>
      @setListeners account

  setListeners:(account)->

    nickname = account.getAt('profile.nickname')
    if nickname
      channelName = 'private-'+nickname+'-private'
      bongo.mq.fetchChannel channelName, (channel)=>
        channel.on 'notification', (notification)=>
          @emit "NotificationHasArrived", notification
          @prepareNotification notification

  prepareNotification: (notification)->

    # NOTIFICATION SAMPLES

    # 1 - < actor fullname > commented on your < activity type >.
    # 2 - < actor fullname > also commented on the < activity type > that you commented.
    # 3 - < actor fullname > liked your < activity type >.

    # 4 - < actor fullname > just sent you a private message.
    log notification, ">>>>"
    options = {}
    {origin, subject, actionType, replier, liker} = notification.contents
    isMine = origin._id is KD.whoami()._id
    actor  = replier or liker
    
    bongo.cacheable actor.constructorName, actor.id, (err, actorAccount)=>
      
      actorName        = "#{actorAccount.profile.firstName} #{actorAccount.profile.lastName}"
      originatorName   = "#{origin.profile.firstName} #{origin.profile.lastName}"
      if actorName is originatorName
        originatorName = "their own"
        separator      = ""
      else
        separator      = "'s"
      
      switch actionType
        when "reply"
          options.title = if isMine
            switch subject.constructorName 
              when "JPrivateMessage"
                "#{actorName} replied to your #{subjectMap()[subject.constructorName]}."
              else
                "#{actorName} commented on your #{subjectMap()[subject.constructorName]}."
          else        # 2
            switch subject.constructorName 
              when "JPrivateMessage"
                "#{actorName} also replied to your #{subjectMap()[subject.constructorName]}."
              else
                "#{actorName} also commented on #{originatorName}#{separator} #{subjectMap()[subject.constructorName]}."

        when "like"   # 3
          options.title = "#{actorName} liked your #{subjectMap()[subject.constructorName]}."

      options.click = ->
        view = @
        if subject.constructorName is "JPrivateMessage"
          appManager.openApplication "Inbox"          
        else
          # ask chris if bongo.cacheable is good for this
          bongo.api[subject.constructorName].one _id : subject.id, (err, post)->
            appManager.tell "Activity", "createContentDisplay", post
            view.destroy()
      options.type  = actionType or ''
      
      @notify options

  notify:(options  = {})->

    options.title or= 'notification arrived'

    new KDNotificationView
      type     : 'tray'
      cssClass : "mini realtime #{options.type}"
      duration : 5000
      title    : "<span></span>#{options.title}"
      content  : options.content  or null
      click    : options.click    or noop


