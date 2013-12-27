class TeamworkChatPane extends ChatPane

  constructor: (options = {}, data) ->

    super options, data

    @setClass "tw-chat"
    @getDelegate().setClass "tw-chat-open"

    @on "NewChatItemCreated", @bound "checkForSystemAction"

  createDock: ->
    @dock = new KDCustomHTMLView cssClass: "hidden"

  updateCount: (count) ->

  sendMessage: (messageData, isSystemMessage) ->
    cssClass = ""
    nickname = KD.nick()

    if isSystemMessage
      cssClass = "tw-bot-message"
      nickname = "teamwork"

    message    =
      user     : { nickname }
      time     : Date.now()
      body     : messageData.message
      by       : messageData.by
      cssClass : cssClass            or ""
      system   : isSystemMessage     or no

    @chatRef.child(message.time).set message

  createNewChatItem: (params) ->
    return if @shouldBeHidden_ params

    super

  appendToChatItem: (params) ->
    return if @shouldBeHidden_ params

    if params.ownerNickname is "teamwork"
      @createNewChatItem params
    else
      super

  shouldBeHidden_: (params) ->
    {details}       = params
    isSystemMessage = details.system
    originUser      = details.by

    return originUser is KD.nick() and isSystemMessage

  checkForSystemAction: ->
    splitted = @lastMessageBody.split " "
    [key]    = splitted

    messageToMethod =
      help          : "replyForSystemHelp"
      invite        : "replyForInvite"
      watch         : "replyForWatch"
      join          : "replyForJoin"

    splitted.shift() # remove first item and update the array instance
    @[messageToMethod[key]]? splitted

  replyForSystemHelp: ->
    message = """
        If you type,
        "invite username" I can bring someone to your session,
        "watch username"  I will show you their changes in realtime,
        "join sessionKey" I will take you to that session.
        Try me!
      """
    @botReply message

  replyForJoin: (sessionKey) ->
    return if sessionKey.length > 1
    # TODO: fatihacet - we need to use a regex to check it's a real sessionKey
    sessionKey = sessionKey.first

    if sessionKey.indexOf("_") > -1
      @botReply "01001101 ... I am checking this session key, #{sessionKey}.", yes
      @workspace.firebaseRef.child(sessionKey).once "value", (snapshot) =>
        if snapshot.val() is null or not snapshot.val().keys
          @botReply "Sorry, looks like this session is closed by its host, I cannot get you in."
        else
          @botReply "01001010 ... Joining session, #{sessionKey}"
          @workspace.getDelegate().emit "JoinSessionRequested", sessionKey
    else
      # TODO: fatihacet - implement getting the sessionKey via username

  replyForInvite: (usernames) ->
    # TODO: fatihacet - currently invite only first user
    username = usernames.first
    return if usernames.length is 0 or username.trim() is ""

    # TODO: fatihacet
    # Kinda hacky to create user list here to send an invite. Instead of this,
    # I should implement a method in CW that will handle to invite stuff.
    @workspace.createUserList()
    query = { "profile.nickname": username }

    KD.remote.api.JAccount.one query, {}, (err, account) =>
      @workspace.userList.once "UserInvited", =>
        message    = "Sure thing! I invited #{username} for you. I will let you know when they join."
        if usernames.length > 1
          message += "Sorry, you can invite only one person at a time for now. My master is working on this feature. Please type one by one."
        @botReply message

      @workspace.userList.once "UserInviteFailed", =>
        @botReply "Sorry, are you sure your friend's nickname is #{username}? Because I can't find it."

      @workspace.userList.sendInvite account

  replyForWatch: (usernames) ->
    username = usernames.first
    return if usernames.length is 0 or usernames.first.trim is ""

    # TODO: fatihacet - I need to check username is valid and user is in session.
    @workspace.setWatchMode username
    message = """
      Ok. Now you are now watching #{username}. Seems like a nice guy.
      You can type "stop watching" anytime.
    """
    @botReply message

  botReply: (message) ->
    messageData =
      message   : message
      by        :
        nickname: "teamwork"

    @sendMessage messageData, yes
