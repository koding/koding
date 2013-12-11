class BadgeDashboardView extends JView

  constructor: (options = {}, data) ->
    super options, data
    # create badge list
    @prepareDashboard()

  prepareDashboard:->
    @badgeListContainer   = new KDScrollView
      ownScrollBars       : yes
      cssClass            : "badge-dashboard-view"

    @badgeListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-list"
        itemClass         : BadgeListItem

    @getAllBadges()
    @badgeListContainer.addSubView @badgeListController.getListView()

    # create new badge button
    @addBadgeButton = new KDButtonView
      style     : "solid green"
      title     : "add badge"
      callback  : =>
        new NewBadgeForm {@badgeListController}

  getAllBadges: ->
    KD.remote.api.JBadge.listBadges '',(err, badges)=>
      return callback err if err
      @badgeListController.instantiateListItems badges

  pistachio:->
    """
    {{> @addBadgeButton}}
    {{> @badgeListContainer}}
    """
