class SingleAppNavigation extends CommonInnerNavigation
  viewAppended:()->
    showController = @setListController {},@showMenuData
    @addSubView showListWrapper = showController.getView()
  
  showMenuData :
    title : "SHOW ME",
    items : [
        { title : "App Info",         type : "appinfo",     }
        { title : "Screenshots",      type : "screenshots", }
        { title : "Reviews",          type : "reviews",     disabledForBeta : yes }
        { title : "Activity",         type : "activity",    disabledForBeta : yes }
        { title : "Get Help!",        type : "gethelp",     disabledForBeta : yes }
      ]
