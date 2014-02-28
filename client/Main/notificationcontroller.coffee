class NotificationController extends KDObject

  subjectMap = ->

    JNewStatusUpdate       : "<a href='#'>status</a>"
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
      @notificationChannel?.off()
      @setListeners()

  setListeners:->

    @notificationChannel = KD.remote.subscribe 'notification',
      serviceType : 'notification'
      isExclusive : yes



    @notificationChannel.off()
    @notificationChannel.on 'message', (notification)=>
      @emit "NotificationHasArrived", notification
      if notification.contents
        @emit notification.event, notification.contents
        @prepareNotification notification

    @on 'GuestTimePeriodHasEnded', ()->
      # todo add a notification to user
      deleteUserCookie()

    deleteUserCookie = ->
      $.cookie 'clientId', erase: yes

    displayEmailConfirmedNotification = (modal)->
      modal.off "KDObjectWillBeDestroyed"
      new KDNotificationView
        title   : "Thanks for confirming your e-mail address"
        duration: 5000
      modal.destroy()

    @once 'EmailShouldBeConfirmed', ->
      {firstName, nickname} = KD.whoami().profile
      KD.getSingleton('appManager').tell 'Account', 'displayConfirmEmailModal', name, nickname, (modal)=>
        @once 'EmailConfirmed', displayEmailConfirmedNotification.bind this, modal
        modal.on "KDObjectWillBeDestroyed", deleteUserCookie.bind this

    @on 'UsernameChanged', ({username, oldUsername}) ->
      # FIXME: because of this (https://app.asana.com/0/search/6604719544802/6432131515387)
      deleteUserCookie()

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
      modal = new KDModalView
        title         : "Permission denied. You've been banned."
        overlay       : yes
        overlayClick  : no
        cancelable    : no
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
              location.reload yes

      # If not clicked on "Ok", kick him out after 10 seconds
      @utils.wait 10000, =>
        $.cookie 'clientId', erase: yes
        location.reload yes

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
    # 10 - < actor fullname > has joined < group title >.
    # 11 - < actor fullname > has left < group title >.

    options = {}
    {origin, subject, actionType, actorType} = notification.contents

    isMine = if origin?._id and origin._id is KD.whoami()._id then yes else no
    actor = notification.contents[actorType]

    return  unless actor

    fetchSubjectObj = (callback)=>
      if not subject or subject.constructorName is "JPrivateMessage"
        return callback null
      if subject.constructorName in ["JComment", "JOpinion"]
        method = 'fetchRelated'
        args   = subject.id
      else
        method = 'one'
        args   = _id: subject.id
      KD.remote.api[subject.constructorName]?[method] args, callback

    KD.remote.cacheable actor.constructorName, actor.id, (err, actorAccount)=>
      # Ignore all guest notifications
      # https://app.asana.com/0/1177356931469/7014047104322
      return  if actorAccount.type is 'unregistered'
      fetchSubjectObj (err, subjectObj)=>

        # TODO: Cross group notifications is not working, so hide for now. -- fka
        # https://app.asana.com/0/3716548652471/7601810287306
        return if err or not subjectObj

        actorName = KD.utils.getFullnameFromAccount actorAccount
        options.actorAvatar = new AvatarView
          size      :
            width   : 35
            height  : 35
          , actorAccount
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
            "#{actorName} has joined <a href='/#{subjectObj.slug}'>#{subjectObj.title}</a>."
          when "groupLeft"
            "#{actorName} has left <a href='/#{subjectObj.slug}'>#{subjectObj.title}</a>."
          else
            if actorType is "follower"
              "#{actorName} started following you."

        if subject
          options.click = ->
            view = this
            if subject.constructorName is "JPrivateMessage"
              KD.getSingleton('router').handleRoute "/Inbox"
            else if subjectObj.constructor.name is "JOpinion"
              KD.remote.api.JOpinion.fetchRelated subjectObj._id, (err, post) ->
                KD.getSingleton('router').handleRoute "/Activity/#{post.slug}", state:post
                view.destroy()
            else if subject.constructorName is 'JGroup'
              suffix = ''
              suffix = '/Dashboard' if actionType is 'groupAccessRequested'
              KD.getSingleton('router').handleRoute "/#{subjectObj.slug}#{suffix}"
              view.destroy()
            else
              KD.getSingleton('router').handleRoute "/Activity/#{subjectObj.slug}", state:subjectObj
              view.destroy()

        options.type  = actionType or actorType or ''
        @notify options

  notify:(options  = {})->

    options.title       or= 'notification arrived'

    notification = new KDNotificationView
      type     : 'tray'
      cssClass : "mini realtime #{options.type}"
      duration : 10000
      title    : "<span></span>#{options.title}"
      content  : options.content  or null

    if options.actorAvatar then notification.addSubView options.actorAvatar

    notification.once 'click', options.click
