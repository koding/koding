class BadgeDashboardView extends JView

  constructor: (options = {}, data) ->
    super options, data
    # create badge list
    @prepareDashboard()


  prepareDashboard:->
    # Containers for split views
    @badgeUserListContainer = new KDScrollView
      ownScrollBars         : yes
      cssClass              : "badge-users-list"
    @badgeListContainer   = new KDScrollView
      ownScrollBars       : yes
      cssClass            : "badge-list"
    @splitView = new KDSplitView
      type      : 'horizontal'
      resizable : yes
      sizes     : ['30%', '70%']
      views     : [@badgeListContainer, @badgeUserListContainer]
    # prepare list views
    @createBadgeListView()
    @createBadgeUserListView()
    # create new badge button
    @addBadge = new KDButtonView
      title     : "add badge"
      callback  : =>
        new NewBadgeForm {@badgeListController}

  createBadgeListView:->
    @badgeListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "item"
        itemClass         : BadgeListItem

    @getAllTheBadges()
    @badgeListContainer.addSubView @badgeListController.getListView()


  createBadgeUserListView:->
    @badgeSelectBox = new KDSelectBox
      name              : "badgeArray"
      setSelectOptions  : [{ title : "No Permission", value : "none"}]
      callback          : (value)=>
        KD.remote.api.JBadge.fetchBadgeUsers value, (err, users)=>
          @badgeUserListController.removeAllItems()
          @badgeUserListController.instantiateListItems users

    @badgeUserListContainer.addSubView @badgeSelectBox

    @badgeUserListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "item"
        itemClass         : BadgeUsersItem

    @badgeUserListContainer.addSubView @badgeUserListController.getListView()


  getAllTheBadges: ->
    KD.remote.api.JBadge.listBadges '',(err, badges)=>
      return callback err if err
      @badgeSelectBox.setSelectOptions @getSelectOptionsArray badges
      @badgeListController.instantiateListItems badges

  getSelectOptionsArray:(badges)->
    barr = []
    for badge in badges
      item = "title":badge.title , "value":badge._id
      barr.push item
    barr

  pistachio:->
    """
    {{> @addBadge}}
    {{> @splitView}}
    """

