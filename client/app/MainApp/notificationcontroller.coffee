class NotificationController extends KDObject

  subjectMap = ->

    JStatusUpdate       : "status update"
    JCodeSnip           : "code snippet"
    JQuestionActivity   : "question"
    JDiscussionActivity : "discussion"
    JLinkActivity       : "link"

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
          @prepareNotification notification

  prepareNotification: (notification)->

    # NOTIFICATION SAMPLES

    # 1 - < user fullname > commented on your < activity type >.
    # 2 - < user fullname > also commented on the < activity type > that you commented.
    # 3 - < user fullname > liked your < activity type >.

    # 4 - < user fullname > just sent you a private message.

    options = {}
    {origin, subject, actionType, replier, liker} = notification.contents
    isMine = origin._id is KD.whoami()._id
    actor  = replier or liker
    log subject.id
    
    bongo.cacheable actor.constructorName, actor.id, (err, actorAccount)=>
      
      actorName = "#{actorAccount.profile.firstName} #{actorAccount.profile.lastName}"
      
      switch actionType
        when "reply"
          if isMine   # 1
            options.title = "#{actorName} commented on your #{subjectMap()[subject.constructorName]}."
          else        # 2
            options.title = "#{actorName} also commented on the #{subjectMap()[subject.constructorName]} that you commented."
        when "like"   # 3
          options.title = "#{actorName} liked your #{subjectMap()[subject.constructorName]}."

      options.click = ->
        view = @
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


