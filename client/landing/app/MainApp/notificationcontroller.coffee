class NotificationController extends KDObject

  subjectMap = ->

    JStatusUpdate       : "<a href='#'>status</a>"
    JCodeSnip           : "<a href='#'>code snippet</a>"
    JQuestionActivity   : "<a href='#'>question</a>"
    JDiscussion         : "<a href='#'>discussion</a>"
    JLinkActivity       : "<a href='#'>link</a>"
    JPrivateMessage     : "<a href='#'>private message</a>"
    JOpinion            : "<a href='#'>opinion</a>"
    JTutorial           : "<a href='#'>tutorial</a>"
    JComment            : "<a href='#'>comment</a>"
    JReview             : "<a href='#'>review</a>"

  constructor:->

    super

    KD.getSingleton('mainController').on "AccountChanged", =>
      @off 'NotificationHasArrived'
      @notificationChannel?.close().off()
      @setListeners()

  setListeners:->

    @notificationChannel = KD.remote.subscribe 'notification',
      serviceType : 'notification'
      isExclusive : yes

    @notificationChannel.on 'message', (notification)=>
      @emit "NotificationHasArrived", notification
      if notification.contents
        @emit notification.event, notification.contents
        @prepareNotification notification

    @on 'UsernameChanged', ({username, oldUsername}) ->

      $.cookie 'clientId', erase: yes

      new KDModalView
        title         : "Your username was changed"
        overlay       : yes
        content       :
          """
          <div class="modalformline">
          Your username has been changed to <strong>#{username}</strong>.
          Your <em>old</em> username <strong>#{oldUsername}</strong> is
          now available for registration by another Koding user.  You have
          been logged out.  If you wish, you may close this box, and save
          your work locally.
          </div>
          """
        buttons       :
          "Refresh":
            style     : "modal-clean-red"
            callback  : (event) -> location.replace '/Login'
          "Close"     :
            style     : "modal-clean-gray"
            callback  : (event) -> modal.destroy()

    @on 'UserBlocked', ({blockedDate}) ->
      new KDModalView
        title         : "Permission denied. You've been banned."
        overlay       : yes
        content       :
          """
          <div class="modalformline">
          You have been blocked until <strong>#{blockedDate}</strong>.
          </div>
          """
        buttons       :
          "Ok"        :
            style     : "modal-clean-gray"
            callback  : (event) ->
              $.cookie 'clientId', erase: yes
              modal.destroy()

      # If not clicked on "Ok", kick him out after 10 seconds
      @utils.wait 10000, =>
        $.cookie 'clientId', erase: yes

  prepareNotification: (notification)->

    # NOTIFICATION SAMPLES

    # 1 - < actor fullname > commented on your < activity type >.
    # 2 - < actor fullname > also commented on the < activity type > that you commented.
    # 3 - < actor fullname > liked your < activity type >.
    # 4 - < actor fullname > sent you a private message.
    # 5 - < actor fullname > replied to your private message.
    # 6 - < actor fullname > also replied to your private message.
    # 7 - Your membership request to < group title > has been approved.
    # 8 - < actor fullname > has requested access to < group title >.
    # 9 - < actor fullname > has invited you to < group title >.
    # 9 - < actor fullname > has joined < group title >.

    options = {}
    {origin, subject, actionType, actorType} = notification.contents

    isMine = if origin?._id and origin._id is KD.whoami()._id then yes else no
    actor = notification.contents[actorType]

    return  unless actor

    KD.remote.cacheable actor.constructorName, actor.id, (err, actorAccount)=>
      KD.remote.api[subject.constructorName].one _id: subject.id, (err, subjectObj)=>

        actorName = KD.utils.getFullnameFromAccount actorAccount

        options.title = switch actionType
          when "reply", "opinion"
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
                  originatorName   = KD.utils.getFullnameFromAccount origin
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
          when "groupRequestApproved"
            "Your membership request to <a href='#'>#{subjectObj.title}</a> has been approved."
          when "groupAccessRequested"
            "#{actorName} has requested access to <a href='#'>#{subjectObj.title}</a>."
          when "groupInvited"
            "#{actorName} has invited you to <a href='#'>#{subjectObj.title}</a>."
          when "groupJoined"
            "#{actorName} has joined <a href='#'>#{subjectObj.title}</a>."
          else
            if actorType is "follower"
              "#{actorName} started following you."

        if subject
          options.click = ->
            view = @
            if subject.constructorName is "JPrivateMessage"
              KD.getSingleton("appManager").openApplication "Inbox"
            else if subject.constructorName in ["JComment", "JOpinion"]
              KD.remote.api[subject.constructorName].fetchRelated subject.id, (err, post) ->
                KD.getSingleton('router').handleRoute "/Activity/#{post.slug}", state:post
                # appManager.tell "Activity", "createContentDisplay", post
                view.destroy()
            else if subject.constructorName is 'JGroup'
              suffix = ''
              suffix = '/Dashboard' if actionType is 'groupAccessRequested'
              KD.getSingleton('router').handleRoute "/#{subjectObj.slug}#{suffix}"
              view.destroy()
            else
              # appManager.tell "Activity", "createContentDisplay", post
              KD.getSingleton('router').handleRoute "/Activity/#{subjectObj.slug}", state:post
              view.destroy()

        options.type  = actionType or actorType or ''

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


