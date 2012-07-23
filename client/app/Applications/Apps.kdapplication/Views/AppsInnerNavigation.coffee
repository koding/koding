class AppsInnerNavigation extends CommonInnerNavigation
  viewAppended:()->
    showController = @setListController {}, @showMenuData
    @addSubView showListWrapper = showController.getView()
    
    sortController = @setListController {}, @sortMenuData, yes
    @addSubView sortListWrapper = sortController.getView()

    @addSubView helpBox = new HelpBox
  
  showMenuData :
    title : "CATEGORIES",
    items : [
        { title : "Web Apps",         type : "web",             action : "change-tab" }
        { title : "Koding Add-ons",   type : "addon",           action : "change-tab" }
        { title : "Server Stacks",    type : "serverstacks",    action : "change-tab" }
        { title : "Frameworks",       type : "frameworks",      action : "change-tab" }
      ]

  sortMenuData :
    title : "SORT"
    items : [
        { title : "Most Popular",     type : "popular",     action : "sort" }
        { title : "Latest Activity",  type : "latest",      action : "sort" }
        { title : "Most Activity",    type : "prolific",    action : "sort" }
      ]
