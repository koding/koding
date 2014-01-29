class CommonInnerNavigation extends KDView

  constructor:(options = {}, data)->

    options.tagName  = 'aside'
    options.cssClass = KD.utils.curry "common-inner-nav", options.cssClass

    super options, data


  setListController:(options, data, isSorter = no)->

    controller = new CommonInnerNavigationListController options, data
    controller.getListView().on "NavItemReceivedClick", (data)=>
      @emit "NavItemReceivedClick", data

    @sortController = controller if isSorter

    return controller

  selectSortItem:(sortType)->
    return unless @sortController
    itemToBeSelected = null
    for item in @sortController.itemsOrdered
      if item.getData().type is sortType
        itemToBeSelected = item

    if itemToBeSelected
      @sortController.selectItem itemToBeSelected


class CommonInnerNavigationListController extends NavigationController

  constructor:(options={}, data)->

    options.viewOptions or=
      itemClass           : options.itemClass or CommonInnerNavigationListItem
    options.scrollView   ?= no
    options.wrapper      ?= no
    options.view        or= new CommonInnerNavigationList options.viewOptions

    super options, data

    listView = @getListView()

    listView.on 'ItemWasAdded', (view)=>
      view.on 'click', (event)=>
        unless view.getData().disabledForBeta
          @selectItem view
          @emit 'NavItemReceivedClick', view.getData()
          listView.emit 'NavItemReceivedClick', view.getData()

  loadView:(mainView)->
    list = @getListView()
    mainView.setClass "list"
    mainView.addSubView new KDHeaderView size : 'small', title : @getData().title, cssClass : "list-group-title"
    mainView.addSubView list
    @instantiateListItems(@getData().items or [])


class CommonInnerNavigationList extends KDListView

  constructor : (options = {}, data)->

    options.tagName or= "nav"
    options.type      = 'inner-nav'

    super options, data

class CommonInnerNavigationListItem extends KDListItemView


  constructor : (options = {},data)->

    options.tagName  or= "a"
    options.attributes = href : data.slug or '#'
    options.partial  or= data.title

    super options, data


  partial:-> ""
