class BadgeDashboardView extends JView

  constructor: (options = {}, data) ->
    super options, data
    # create badge list
    @prepareDashboard()


  prepareDashboard:->
    @badgeListContainer   = new KDScrollView
      ownScrollBars       : yes
      cssClass            : "badge-dashboard-view"

    @createBadgeListView()

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


  getAllTheBadges: ->
    KD.remote.api.JBadge.listBadges '',(err, badges)=>
      return callback err if err
      @badgeListController.instantiateListItems badges

  getSelectOptionsArray:(badges)->
    barr = []
    for badge in badges
      item = "title":badge.title , "value":badge._id
      barr.push item
    barr

  viewAppended: JView::viewAppended

  pistachio:->
    """
    {{> @addBadge}}
    {{> @badgeListContainer}}
    """

