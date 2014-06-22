class NotificationController extends KDObject

  subjectMap = ->

    JNewStatusUpdate : "<a href='#'>status</a>"
    JPrivateMessage  : "<a href='#'>private message</a>"
    JComment         : "<a href='#'>comment</a>"

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

    @on 'ChannelUpdateHappened', (notification) =>
      @emit notification.event, notification  if notification.event

    @on 'GuestTimePeriodHasEnded', ()->
      # todo add a notification to user
      deleteUserCookie()

    deleteUserCookie = ->
      Cookies.expire 'clientId'

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
            Hello,
            This account has been put on suspension by Koding moderators due to violation of our <a href="https://koding.com/acceptable.html">acceptable use policy</a>. The ban will be in effect until <strong>#{blockedDate}</strong> at which time you will be able to log back in again. If you have any questions regarding this ban, please write to <a href='mailto:ban@koding.com?subject=Username: #{KD.whoami().profile.nickname}'>ban@koding.com</a> and allow 2-3 business days for us to research and reply. Even though your account is banned, all your data is safe and will be accessible once the ban is lifted.<br><br>

            Please note, repeated violations of our <a href="https://koding.com/acceptable.html">acceptable use policy</a> will result in the permanent deletion of your account.<br><br>

            Team Koding
          </div>
          """
        buttons       :
          "Ok"        :
            style     : "modal-clean-gray"
            callback  : (event) ->
              Cookies.expire 'clientId'
              modal.destroy()
              location.reload yes

      # If not clicked on "Ok", kick him out after 10 seconds
      @utils.wait 10000, =>
        Cookies.expire 'clientId'
        location.reload yes

  fetchActor: (contents) ->
    new Promise (resolve, reject) =>
      {actorId} = contents
      KD.remote.api.JAccount.one _id: actorId, (err, actor) =>
        return reject err  if err
        return reject {message: "actor not found"}  unless actor
        resolve {actor, contents}


  fetchTarget: (data)->
    new Promise (resolve, reject) =>
      helper = (err, target) ->
        return reject err  if err
        data.target = target
        resolve data

      {targetId, type} = data.contents
      switch type
        when "comment", "like"
          KD.remote.api.SocialMessage.fetch id: targetId, helper
        when "follow"
          KD.remote.api.JAccount.one socialApiId: targetId, helper
        when "join", "leave"
          KD.remote.api.JGroup.one socialApiChannelId: targetId, helper
        else
          resolve data


  prepareMessage: (data) ->
    options = {}
    options.actorAvatar = new AvatarView
      size      :
        width   : 35
        height  : 35
      , data.actor

    @prepareTitle data, options


  prepareTitle: (data, options) ->
    new Promise (resolve, reject) ->
      {actor, contents, target} = data
      actorName = KD.utils.getFullnameFromAccount actor
      setTitle = (title) ->
        options.title = title
        resolve options

      switch contents.type
        when "comment"
          isMine = target.accountOldId is KD.whoami()?.getId()
          subject = if target.type is "privateMessage" then "private message" else "status"
          if isMine then setTitle "#{actorName} commented on your #{subject}"
          else
            KD.remote.api.JAccount.one _id: target.accountOldId, (err, origin)->
              return reject err  if err
              return reject {message: "message origin not found"}  unless origin

              if origin.getId() is actor.getId()
                ownerName = "their own"
              else
                ownerName = KD.utils.getFullnameFromAccount actor
                ownerName = "#{ownerName}'s"
              setTitle "#{actorName} commented on #{ownerName} #{subject}"
        when "like"
          setTitle "#{actorName} liked your status."
        when "follow"
          setTitle "#{actorName} started following you."
        when "join"
          setTitle "#{actorName} has joined <a href='/#{target.slug}'>#{target.title}</a>."
        when "leave"
          setTitle "#{actorName} has left <a href='/#{target.slug}'>#{target.title}</a>."
        when "mention"
          setTitle "#{actorName} mentioned you in a comment"

      # when "newMessage"
      #   @emit "NewMessageArrived"
      #   "#{actorName} sent you a #{subjectMap()[subject.constructorName]}."
      # when "groupInvited"
      #   "#{actorName} has invited you to <a href='#'>#{subjectObj.title}</a>."


  prepareClick: (data, options) ->
    {target, contents} = data
    if target
      options.click = ->
        view = this
        if contents.type in ["comment", "like"]
          # TODO group slug must be prepended after groups are implemented
          # groupSlug = if target.group is "koding" then "" else "/#{target.group}"
          KD.getSingleton('router').handleRoute "/Activity/Post/#{target.message.slug}", state:target
          view.destroy()
        else if contents.type in ["join", "leave"]
          KD.getSingleton('router').handleRoute "/#{target.slug}"
          view.destroy()


  # NOTIFICATION SAMPLES

  # 1 - < actor fullname > commented on your < activity type >.
  # 2 - < actor fullname > also commented on the < activity type > that you commented.
  # 3 - < actor fullname > liked your < activity type >.
  # 4 - < actor fullname > sent you a private message.
  # 5 - < actor fullname > replied to your private message.
  # 6 - < actor fullname > also replied to your private message.
  # 7 - < actor fullname > has invited you to < group title >.
  # 8 - < actor fullname > has joined < group title >.
  # 9 - < actor fullname > has left < group title >.

  prepareNotification: (notification)->
    {contents} = notification
    @fetchActor(contents).then (data) =>
      @fetchTarget(data).then (data) =>
        @prepareMessage(data).then (options) =>
          @prepareClick data, options
          @notify options
        .catch (err) ->
          warn err  if err


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
