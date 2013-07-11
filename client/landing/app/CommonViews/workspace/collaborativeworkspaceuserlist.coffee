class CollaborativeWorkspaceUserList extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-list-container"

    super options, data

    {@workspaceRef, @container, @sessionKey} = @getOptions()

    @header = new KDView
      cssClass : "inner-header"
      partial  : """<span class="title">Users</span>"""

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
      val       = snapshot.val()
      userList  = {}
      userNames = []

      for userName, status of val.users
        userList[userName] = status
        userNames.push userName

      KD.remote.api.JAccount.some { "profile.nickname": { "$in": userNames } }, {}, (err, jAccounts) =>
        @loaderView.hide()
        for user in jAccounts
          user.status = userList[user.profile.nickname]
          @createUserView user

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

    [sessionOwner] = @sessionKey.split ":"
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
      partial     : """
        <p>You can share your session key with your friends or type a name to send an invite to your session.</p>
      """

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
        @sendInvite account for account in accounts
        @reset()

  sendInvite: (account) ->
    to         = account.profile.nickname
    nickname   = KD.nick()
    {profile}  = KD.whoami()
    userName   = "#{profile.firstName} #{profile.lastName} (@#{nickname})"
    subject    = "Collaborative IDE Session Invite"
    body       = "My session key is: #{@getDelegate().sessionKey}"

    return if to is nickname

    KD.remote.api.JPrivateMessage.create { to, subject, body }

    new KDNotificationView
      title    : "Invitation sent to #{to}"
      duration : 3000
      type     : "tray"

    @workspaceRef.child("users").child(to).set "invited"

  returnToInviteView: ->
    for key in ["onlineUsers", "offlineUsers", "invitedUsers"]
      @[key].show() if @[key].getSubViews().length > 0

    @inviteView.setClass "hidden"
    @inviteBar.show()

  close: ->
    container = @container
    container.unsetClass "active"
    container.once "transitionend", -> container.destroySubViews()
    @getDelegate().userListVisible = no

  reset: ->
    @container.destroySubViews()
    @getDelegate().userListVisible = no
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