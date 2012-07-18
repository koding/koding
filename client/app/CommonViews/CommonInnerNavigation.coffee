class CommonInnerNavigation extends KDView
  constructor:->
    super
    @setClass "common-inner-nav"
  
  setListController:(options,data,isSorter = no)->
    controller = new CommonInnerNavigationListController options, data
    controller.getListView().registerListener 
      KDEventTypes :"CommonInnerNavigationListItemReceivedClick"
      listener     : @
      callback     : (pubInst, data)=>
        @propagateEvent  KDEventType : "CommonInnerNavigationListItemReceivedClick", data
    if isSorter
      @sortController = controller
    return controller

  selectSortItem:(sortType)->
    return unless @sortController
    itemToBeSelected = null
    for item in @sortController.itemsOrdered
      if item.getData().type is sortType
        itemToBeSelected = item

    if itemToBeSelected
      @sortController.selectItem itemToBeSelected

class CommonInnerNavigationListController extends KDListViewController
  constructor:(options={},data)->
    options.viewOptions or= subItemClass : options.subItemClass or CommonInnerNavigationListItem
    options.view or= mainView = new CommonInnerNavigationList options.viewOptions
    super options,data
    
    listView = @getListView()
    
    listView.on 'ItemWasAdded', (view)=>
      view.registerListener
        KDEventTypes    : 'click'
        listener        : @
        callback        : (pubInst, event)=>
          unless view.getData().disabledForBeta
            @selectItem view
            @propagateEvent KDEventType:'CommonInnerNavigationListItemReceivedClick', (pubInst.getData())
            listView.propagateEvent KDEventType:'CommonInnerNavigationListItemReceivedClick', (pubInst.getData())
    
  loadView:(mainView)->
    list = @getListView()
    mainView.setClass "list"
    mainView.addSubView new KDHeaderView size : 'small', title : @getData().title, cssClass : "list-group-title"
    mainView.addSubView list
    @instantiateListItems(@getData().items or [])
  
class CommonInnerNavigationList extends KDListView
  constructor : (options = {},data)->
    options.tagName or= "ul"
    super options,data

class CommonInnerNavigationListItem extends KDListItemView
  constructor : (options = {},data)->
    options.tagName or= "li"
    options.partial or= "<a href='#'>#{data.title}</a>"
    if data.disabledForBeta
      options = $.extend
        tooltip     :
          title     : "<p class='login-tip'>Coming Soon</p>"
          placement : "right"
          offset    : 3
      ,options
    super options,data
    @setClass data.type

  partial:()-> ""
