class CollaborativeWorkspaceUserList extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-list-container"

    super options, data

    {@workspaceRef, @container, @sessionKey} = @getOptions()

    @header = new KDView
      cssClass : "inner-header"
      partial  : """<span class="title">Participants</span>"""

    @header.addSubView new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "close"
      click     : @bound "close"

    @loaderView   = new KDLoaderView
      size        :
        width     : 36

    @onlineUsers  = new KDView
      cssClass    : "group online hidden"
      partial     : """<p class="header">ONLINE</p>"""

    @offlineUsers = new KDView
      cssClass    : "group offline hidden"
      partial     : """<p class="header">OFFLINE</p>"""

    @invitedUsers = new KDView
      cssClass    : "group invited hidden"
      partial     : """<p class="header">INVITED</p>"""

    @inviteBar    = new KDView
      partial     : "Invite Friends"
      cssClass    : "invite-bar"
      click       : @bound "showInviteView"

    @createInviteView()

    @fetchUsers()

    KD.getSingleton("windowController").addLayer @

    @on "ReceivedClickElsewhere", @bound "close"

  fetchUsers: ->
    @workspaceRef.once "value", (snapshot) =>
      val       = @getDelegate().reviveSnapshot snapshot
      userList  = {}
      userNames = []

      for own userName, status of val.users
        userList[userName] = status
        userNames.push userName

      KD.remote.api.JAccount.some { "profile.nickname": { "$in": userNames } }, {}, (err, jAccounts) =>
        @loaderView.hide()
        for user in jAccounts
          user.status = userList[user.profile.nickname]
          @createUserView user

        @emit "UserListCreated"

  createUserView: (user) ->
    userView      = new KDView
      cssClass    : "user-view #{user.status}"

    avatarOptions =
      size        :
        width     : 36
        height    : 36

    userView.addSubView new AvatarView avatarOptions, user
    userView.addSubView new KDView
      cssClass    : "user-name"
      partial     :
        """
          <p>#{user.profile.firstName} #{user.profile.lastName}</p>
          <p>#{user.profile.nickname}</p>
        """

    [sessionOwner] = @sessionKey.split "_"
    if user.profile.nickname is sessionOwner
      userView.addSubView new KDView
        cssClass : "host-badge"
        partial  : """<span class="icon"></span> HOST"""

    container = @onlineUsers
    if user.status is "offline"
      container = @offlineUsers
    else if user.status is "invited"
      container = @invitedUsers

    container.addSubView userView
    container.unsetClass "hidden"

  showInviteView: ->
    @[key].hide() for key in ["onlineUsers", "offlineUsers", "invitedUsers", "inviteBar"]
    @inviteView.unsetClass "hidden"

  createInviteView: ->
    @inviteView   = new KDView
      cssClass    : "invite-view hidden"
      partial     : "<p>You can share your session key with your friends or type a name to send an invite to your session.</p>"

    @inviteView.addSubView new KDView
      cssClass    : "session-key"
      partial     : @sessionKey

    @userController = new KDAutoCompleteController
      form                : new KDFormView
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : @completedItems
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback) =>
        {inputValue} = args
        blacklist    = (data.getId() for data in @userController.getSelectedItemData())
        blacklist.push KD.whoami()._id
        KD.remote.api.JAccount.byRelevance inputValue, {blacklist}, (err, accounts) =>
          callback accounts

    @userController.on "ItemListChanged", =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0 then @inviteButton.enable() else @inviteButton.disable()

    @inviteView.addSubView @userController.getView()

    @inviteView.addSubView @completedItems = new KDView
      cssClass : "completed-items"

    @inviteView.addSubView @cancelInviteButton = new KDButtonView
      cssClass : "invite-button cancel-button"
      title    : "Cancel"
      callback : @bound "returnToInviteView"

    @inviteView.addSubView @inviteButton = new KDButtonView
      cssClass : "invite-button cupid-green"
      title    : "Invite"
      callback : =>
        accounts  = @userController.getSelectedItemData()
        @sendInviteTo account for account in accounts
        @reset()

  sendInviteTo: (account) ->
    return @emit "UserInviteFailed"  unless account

    to           = account.profile.nickname
    nickname     = KD.nick()
    {profile}    = KD.whoami()
    fromFullName = "#{profile.firstName} #{profile.lastName}"
    delegate     = @getDelegate()
    appName      = delegate.getOptions().name
    {sessionKey} = delegate
    userName     = "#{profile.firstName} #{profile.lastName} (@#{nickname})"
    subject      = "Join my #{appName} session"
    body         =
      """
        Hi @#{account.profile.nickname},

        @#{profile.nickname} has invited you to join #{KD.utils.formatIndefiniteArticle appName} session.

        To join, click the link below:

        https://koding.com/#{encodeURIComponent appName}?sessionKey=#{encodeURIComponent sessionKey}
      """

    return if to is nickname

    KD.remote.api.JPrivateMessage.create { to, subject, body }, noop

    @workspaceRef.child("users").child(to).set "invited"
    @emit "UserInvited", to

  returnToInviteView: ->
    for key in ["onlineUsers", "offlineUsers", "invitedUsers"]
      @[key].show() if @[key].getSubViews().length > 0

    @inviteView.setClass "hidden"
    @inviteBar.show()

  close: ->
    container = @container
    return  unless container
    container.unsetClass "active"
    container.once "transitionend", =>
      container.destroySubViews()
      delete @getDelegate().userList

  reset: ->
    @container.destroySubViews()
    @getDelegate().showUsers()

  viewAppended: ->
    super
    @loaderView.show()

  pistachio: ->
    """
      {{> @header}}
      {{> @loaderView}}
      {{> @onlineUsers}}
      {{> @offlineUsers}}
      {{> @invitedUsers}}
      {{> @inviteBar}}
      {{> @inviteView}}
    """