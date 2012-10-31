class NotificationController extends KDObject

  subjectMap = ->

    JStatusUpdate       : "<a href='#'>status</a>"
    JCodeSnip           : "<a href='#'>code snippet</a>"
    JQuestionActivity   : "<a href='#'>question</a>"
    JDiscussionActivity : "<a href='#'>discussion</a>"
    JLinkActivity       : "<a href='#'>link</a>"
    JPrivateMessage     : "<a href='#'>private message</a>"
    JOpinionActivity    : "<a href='#'>opinion</a>"
    JComment            : "<a href='#'>comment</a>"
    JReview             : "<a href='#'>review</a>"

  constructor:->

    super

    @getSingleton('mainController').on "AccountChanged", (account)=>
      if account.bongo_.constructorName is 'JAccount'
        @setListeners account

  setListeners:(account)->

    nickname = account.getAt('profile.nickname')
    if nickname
      # channelName = 'private-'+nickname+'-private'
      # KD.remote.fetchChannel channelName, (channel)=>
      #  channel.on 'notificationArrived', (notification)=>
      account.on 'notificationArrived', (notification) =>
        @emit "NotificationHasArrived", notification
        @prepareNotification notification if notification.contents

  prepareNotification: (notification)->

    # NOTIFICATION SAMPLES

    # 1 - < actor fullname > commented on your < activity type >.
    # 2 - < actor fullname > also commented on the < activity type > that you commented.
    # 3 - < actor fullname > liked your < activity type >.
    # 4 - < actor fullname > sent you a private message.
    # 5 - < actor fullname > replied to your private message.
    # 6 - < actor fullname > also replied to your private message.

    options = {}
    {origin, subject, actionType, replier, liker, sender} = notification.contents

    isMine = if origin?._id and origin._id is KD.whoami()._id then yes else no
    actor  = replier or liker or sender

    KD.remote.cacheable actor.constructorName, actor.id, (err, actorAccount)=>

      actorName = "#{actorAccount.profile.firstName} #{actorAccount.profile.lastName}"

      options.title = switch actionType
        when "reply"
          if isMine
            switch subject.constructorName
              when "JPrivateMessage"
                "#{actorName} replied to your #{subjectMap()[subject.constructorName]}."
              else
                "#{actorName} commented on your #{subjectMap()[subject.constructorName]}."
          else
            switch subject.constructorName
              when "JPrivateMessage"
                "#{actorName} also replied to your #{subjectMap()[subject.constructorName]}."
              else
                originatorName   = "#{origin.profile.firstName} #{origin.profile.lastName}"
                if actorName is originatorName
                  originatorName = "their own"
                  separator      = ""
                else
                  separator      = "'s"
                "#{actorName} also commented on #{originatorName}#{separator} #{subjectMap()[subject.constructorName]}."

        when "like"
          "#{actorName} liked your #{subjectMap()[subject.constructorName]}."
        when "newMessage"
          @emit "NewMessageArrived"
          "#{actorName} sent you a #{subjectMap()[subject.constructorName]}."

      options.click = ->
        view = @
        if subject.constructorName is "JPrivateMessage"
          appManager.openApplication "Inbox"
        else if subject.constructorName is "JComment"
          KD.remote.api[subject.constructorName].fetchRelated subject.id, (err, post) ->
            appManager.tell "Activity", "createContentDisplay", post
            view.destroy()
        else
          # ask chris if KD.remote.cacheable is good for this
          KD.remote.api[subject.constructorName].one _id : subject.id, (err, post)->
            appManager.tell "Activity", "createContentDisplay", post
            view.destroy()
      options.type  = actionType or ''

      @notify options

  notify:(options  = {})->

    options.title or= 'notification arrived'

    notification = new KDNotificationView
      type     : 'tray'
      cssClass : "mini realtime #{options.type}"
      duration : 10000
      showTimer: yes
      title    : "<span></span>#{options.title}"
      content  : options.content  or null

    notification.once 'click', options.click


