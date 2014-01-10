class BadgeUsersList extends KDView
  constructor:(options = {}, data) ->
    super options, data
    {@badge}                 = @getOptions()
    @filteredUsersController = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "users"
        cssClass             : "user-list"
        itemClass            : BadgeUsersItem

    @userView = @filteredUsersController.getView()
    listView = @filteredUsersController.getListView()
    listView.on "RemoveBadgeUser", (account) =>
      @badge.removeBadgeFromUser account, (err, account)->
        return KD.showError err if err
        new KDNotificationView
          title     : "Badge removed"
          duration  : 2000

  loadUserList:->
    # TODO : after style of scrollView fixed, we will need pagination
    KD.remote.api.JBadge.fetchBadgeUsers @badge.getId(), limit:100 ,(err, accounts)=>
      @filteredUsersController.replaceAllItems accounts

  viewAppended:->
    @addSubView @userView
    @loadUserList()
