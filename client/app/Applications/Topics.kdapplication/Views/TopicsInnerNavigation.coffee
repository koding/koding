class TopicsInnerNavigation extends CommonInnerNavigation
  viewAppended:()->
    showController = @setListController {},@showMenuData
    @addSubView showListWrapper = showController.getView()

    showItemToBeSelected = showController.getItemsOrdered()[0]
    showController.selectItem showItemToBeSelected

    sortController = @setListController {},@sortMenuData, yes
    @addSubView sortListWrapper = sortController.getView()

    # fixme why timeout
    setTimeout =>
      @emit "NavItemReceivedClick", showItemToBeSelected.getData()
    ,10

    @addSubView helpBox = new HelpBox

  showMenuData :
    title : "SHOW ME",
    items : [
        { title : "All Topics",       type : "all",         action : "change-tab" }
        { title : "Followed",         type : "followed",    action : "change-tab" }
        { title : "Recommended",      type : "recommended", action : "change-tab" }
      ]

  sortMenuData :
    title : "SORT"
    items : [
        { title : "Most Popular",     type : "popular",     action : "sort" }
        { title : "Latest Activity",  type : "latest",      action : "sort" }
        { title : "Most Activity",    type : "prolific",    action : "sort" }
      ]
