class BadgeDashboardView extends JView

  constructor: (options = {}, data) ->
    super options, data

    # create badge list
    @createBadgeComponents()


  createBadgeComponents:->
    @badgeListContainer   = new KDView
      cssClass            : "badge-list"

    @badgeListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "item"
        itemClass         : BadgeListItem

    @listAllTheBadges()


    # create new badge button
    @addBadge = new KDButtonView
      title     : "add badge"
      callback  : =>
        new NewBadgeForm {@badgeListController}

  listAllTheBadges: ->
    @badgeListContainer.addSubView @badgeListController.getView()
    KD.remote.api.JBadge.listBadges '',(err, badges)=>
      return callback err if err
      @badgeListController.instantiateListItems badges

  addNewBadgeForm:->
    @badgeListContainer.addSubView badgeForm

  pistachio:->
    """
    {{> @addBadge}}
    {{> @badgeListContainer}}
    """

