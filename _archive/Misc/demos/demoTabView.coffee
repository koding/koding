page_demoTabView = (parentView)->
  top = new KDView()
  bottom = new KDView()
  HomeView = new SplitView
    type  : "horizontal"
    views : [top,bottom]
    sizes : ["20%","80%"]

  bottomLeft = new KDView()
  bottomMiddle = new KDView()
  bottomRight = new KDView()

  bottomSplit = new SplitView
    views : [bottomLeft,bottomMiddle,bottomRight]
    sizes : ["33%","34%","33%"]

  parentView.addSubView HomeView
  bottom.addSubView bottomSplit

  tabHandleContainer = new KDView()
  tabHandleContainer1 = new KDView()

  activityLists = new KDTabView()
  activityLists.setTabHandleContainer tabHandleContainer
  activityLists1 = new KDTabView()
  activityLists1.setTabHandleContainer tabHandleContainer1
  activityLists2 = new KDTabView()

  top.addSubView tabHandleContainer
  top.addSubView tabHandleContainer1

  buttonAddTab = new KDButtonView
    title       : "Add a tab to right"
    callback    : ()->
      newTab = new KDTabPaneView null,null
      newTab.setRandomBG()
      activityLists.addPane newTab 

  buttonAddTab1 = new KDButtonView
    title       : "Add a tab to bottom"
    callback    : ()->
      newTab = new KDTabPaneView null,null
      newTab.setRandomBG()
      activityLists1.addPane newTab 

  buttonAddTab2 = new KDButtonView
    title       : "Add a tab to center"
    callback    : ()->
      newTab = new KDTabPaneView null,null
      newTab.setRandomBG()
      activityLists2.addPane newTab 

  buttonShowHandles = new KDButtonView
    title       : "Toggle tab Handles right"
    callback    : ()->
      activityLists.toggleHandleContainer()
  buttonShowHandles1 = new KDButtonView
    title       : "Toggle tab Handles bottom"
    callback    : ()->
      activityLists1.toggleHandleContainer()

  bottomLeft.addSubView buttonAddTab
  bottomLeft.addSubView buttonAddTab1
  bottomLeft.addSubView buttonAddTab2
  bottomLeft.addSubView buttonShowHandles
  bottomLeft.addSubView buttonShowHandles1
  bottomRight.addSubView activityLists
  bottomLeft.addSubView activityLists1
  bottomMiddle.addSubView activityLists2
  activityLists1.hideHandleCloseIcons()
