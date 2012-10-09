class FeederFacetsController extends KDViewController
  constructor:(options, data)->
    options.view or= new KDView cssClass: 'common-inner-nav'
    super

  loadView:(mainView)->
    options = @getOptions()

    @filterController = new CommonInnerNavigationListController {},
      title     : options.filterTitle or 'FILTER'
      items     : (
        title   : item.title
        type    : type
        action  : 'filter'
      ) for own type, item of options.filters

    @sortController = new CommonInnerNavigationListController {},
      title     : options.sortTitle or 'SORT'
      items     : (
        title   : item.title
        type    : type
        action  : 'sort'
      ) for own type, item of options.sorts

    view = @getView()

    if @filterController.getData().items.length > 1
      @filterController.on 'NavItemReceivedClick', (item)=>
        @propagateEvent KDEventType: 'FilterDidChange', item
      view.addSubView @filterController.getView()

    if @sortController.getData().items.length > 1
      @sortController.on 'NavItemReceivedClick', (item)=>
        @propagateEvent KDEventType: 'SortDidChange', item
      view.addSubView @sortController.getView()


    view.addSubView new HelpBox @getOptions().help


  highlight:(filterName,sortName)->

    for item in @filterController.itemsOrdered
      if item.getData().type is filterName and @filterController.itemsOrdered.length > 1
        @filterController.selectItem item

    for item in @sortController.itemsOrdered
      if item.getData().type is sortName and @sortController.itemsOrdered.length > 1
        @sortController.selectItem item



