class BadgeDashboardView extends JView

  constructor: (options = {}, data) ->
    super options, data
    # create badge list

    # create new badge button
    @addBadgeButton = new KDButtonView
      style         : "solid green"
      title         : "add badge"
      callback      : =>
        new NewBadgeForm {@badgeListController}

    @badgeListController  = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-list"
        itemClass         : BadgeListItem

    KD.remote.api.JBadge.listBadges {},limit:50 ,(err, badges)=>
      if err
        log "Couldn't fetch badges", err
      else
        @badgeListController.instantiateListItems badges

    @badgeListView = @badgeListController.getListView()

  pistachio:->
    """
    {{> @addBadgeButton}}
    {{> @badgeListView}}
    """
