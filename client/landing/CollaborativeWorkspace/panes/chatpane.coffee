class ChatPane extends JView

  constructor: (options = {}, data) ->

    floatingCssClass = if options.floating then "floating" else ""
    options.cssClass = KD.utils.curry "workspace-chat", floatingCssClass
    options.dock   or= no

    super options, data

    @unreadCount = 0
    @hasDock     = @getOptions().dock
    @workspace   = @getDelegate()
    @chatRef     = @workspace.workspaceRef.child "chat"
    @messages    = new KDView
      cssClass   : "messages"
    @avatar      = new AvatarView
      cssClass   : "ws-chat-avatar"
      size       :
        width    : 24
        height   : 24
    , KD.whoami()
    @input       = new KDHitEnterInputView
      type       : "text"
      callback   : =>
        nickname = KD.nick()
        message  =
          user   : { nickname }
          time   : Date.now()
          body   : @input.getValue()

        @chatRef.child(message.time).set message
        @input.setValue ""
        @input.setFocus()

    if @hasDock then @createDock() else @setClass "no-dock"

    @chatRef.on "child_added", (snapshot) =>
      unless @isVisible() or @getOptions().floating or not @hasDock
        @title.updatePartial "Chat (#{++@unreadCount})"
        @dock.setClass "pulsing"

      @utils.wait 300, => @addNew snapshot.val() # to prevent a possible race condition

    workspace = @getDelegate()
    workspace.on "WorkspaceSyncedWithRemote", =>
      if workspace.amIHost()
        message =
          user       :
            nickname : "teamwork"
          time       : Date.now()
          body       : "Welcome to Teamwork! Type help for more options."

        @chatRef.child(message.time).set message

      workspace.avatarsView = new KDCustomHTMLView
        cssClass   : "tw-users"
        partial    : "<p>There is nobody in this session. Your friends will be visible here. To invite your friend, type invite username.<p>"

      @addSubView workspace.avatarsView, null, yes

  isVisible: -> return @hasClass "active"

  addNew: (details) ->
    ownerNickname = details.user.nickname
    if @lastChatItemOwner is ownerNickname and @lastChatItemOwner isnt "teamwork"
      @lastChatItem.messageList.addSubView new KDCustomHTMLView
        partial : KD.utils.xssEncode details.body
      return @messageAddedCallback details

    @lastChatItem      = new ChatItem details, @workspace.users[ownerNickname]
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @messageAddedCallback details

  messageAddedCallback: (details) ->
    @updateDate details.time
    @checkForSystemReply details  if @workspace.amIHost()
    @scrollToTop()

  updateDate: (timestamp) ->
    @lastChatItem.timeAgo.setData new Date timestamp

  scrollToTop: ->
    $messages = @messages.$()
    $messages.scrollTop $messages[0].scrollHeight

  checkForSystemReply: (details) ->
    return @createHelpContent() if details.body is "help"
    workspace = @getDelegate()
    splitted  = details.body.split " "
    [command] = splitted
    splitted.shift()

    switch command
      when "invite"
        workspace.createUserList()
        query = { "profile.nickname": splitted.first }
        KD.remote.api.JAccount.one query, {}, (err, account) =>
          workspace.userList.once "UserInvited", =>
            message =
              user       :
                nickname : "teamwork"
              time       : Date.now()
              body       : "#{account.profile.nickname} is invited."
            @chatRef.child(message.time).set message

          workspace.userList.once "UserInviteFailed", =>
            message =
              user       :
                nickname : "teamwork"
              time       : Date.now()
              body       : "Are you sure your friend's nickname is #{splitted.first}?"
            @chatRef.child(message.time).set message

          workspace.userList.sendInvite account
      when "watch"
        workspace.setWatchMode splitted.first
        message =
          user       :
            nickname : "teamwork"
          time       : Date.now()
          body       : """
            Ok I set it up for you. Now you will see the changes that only made by #{splitted.first}. NEW_LINE NEW_LINE
            Type "watch nobody" for stop watching #{splitted.first} or type "watch username" to watch someone else.
          """
        @chatRef.child(message.time).set message
      when "join"
        message =
          user       :
            nickname : "teamwork"
          time       : Date.now()
          body       : """
            Cool. Launching a new space shuttle to #{splitted.first}. Are you ready?
          """
        @chatRef.child(message.time).set message
        KD.utils.wait 2000, ->
          workspace.getDelegate().emit "JoinSessionRequested", splitted.first

  createHelpContent: ->
    message =
      user       :
        nickname : "teamwork"
      time       : Date.now()
      body       : """
        Type "invite username" to invite someone to your session. NEW_LINE
        Type "watch username"  to watch changes of somebody. NEW_LINE
        Type "join sessionKey" to join a session.
      """

    @chatRef.child(message.time).set message

  createDock: ->
    @dock        = new KDView
      cssClass   : "dock"
      click      : =>
        @dock.unsetClass "pulsing"
        @toggleClass "active"
        @toggle.toggleClass "active"
        @unreadCount = 0
        @title.updatePartial "Chat"
        @emit "WorkspaceChatClosed"  unless @isVisible()

    @title       = new KDCustomHTMLView
      tagName    : "span"
      partial    : "Chat"

    @toggle      = new KDView cssClass : "toggle"

    @dock.addSubView @toggle
    @dock.addSubView @title

  pistachio: ->
    dock = if @hasDock then "{{> @dock}}" else ""
    """
      #{dock}
      {{> @messages}}
      <div class="input-container">
        {{> @avatar}}
        {{> @input}}
      </div>
    """
