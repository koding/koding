class FatihUserSearchPlugin extends FatihPluginAbstract

  constructor: (options = {}, data) ->

    options.name          = "User Search"
    options.keyword       = "user"
    options.notFoundText  = "Cannot find a user like that."
    options.itemCssClass  = "fatih-user-search-plugin"

    super options, data

    @on "UserActionSelected", (action, user) =>
      {nickname} = user.profile
      switch action
        when "message" then KD.getSingleton("appManager").tell "Inbox", "composeNewMessage", user
        when "profile" then KD.getSingleton("router").handleRoute "/#{nickname}"
      @fatihView.destroy()

  fetchUsers: (keyword) ->
    KD.remote.api.JAccount.byRelevance keyword[0], {}, (err,res) =>
      @emit "FatihPluginCreatedAList", res, FatihUserListItem

  selectActionOnUser: (user) ->
    @fatihView.destroyPluginSubViews yes
    actionsView = new FatihUserActionView {}, user
    @fatihView.emit "PluginViewReadyToShow", actionsView

  action: [ "fetchUsers", "selectActionOnUser" ]


class FatihUserActionView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = "fatih-user-actions"

    super options, data

    [user]      = @getData()
    {nickname}  = user.profile

    actionTypes =
      "profile" : "View profile"
      "message" : "Send Message"

    @addSubView avatar = new AvatarView
      size     :
        width  : 36
        height : 36
    , user

    for own action of actionTypes
      do (action) =>
        @addSubView new KDButtonView
          title     : actionTypes[action]
          callback  : => @emit "UserActionSelected", action, user
        , user      : user


class FatihUserListItem extends FatihListItem

  constructor: (options = {}, data) ->

    options.cssClass = "fatih-user-item"

    super options, data

    @avatar = new AvatarView
      size     :
        width  : 36
        height : 36
    , @getData()

    @avatar.on "click", ->
      @plugin.destroy()

  click: ->
    @plugin.emit "FatihNextAction", @getData()

  viewAppended: ->
    super
    @setTemplate @pistachio()

  partial: -> "" # I need pistachioooo!

  pistachio: ->
    {profile} = @getData()
    """
      {{> @avatar}}
      <div class="user-details">
        <div class="user-name">#{profile.firstName} #{profile.lastName}</div>
        <div class="user-nickname">#{profile.nickname}</div>
      </div>
    """