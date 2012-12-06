class FeederFacetsController extends KDViewController
  constructor:(options, data)->
    options.view or= new KDView cssClass: 'common-inner-nav'
    super
    # the order of these facetTypes is the order they'll be displayed in
    @facetTypes = ['filter', 'sort']
    @state = {}

  facetChange:-> KD.getSingleton('router').handleQuery @state

  loadView:(mainView)->
    options = @getOptions()
    view = @getView()

    @facetTypes.forEach (facet)=>

      controller = new CommonInnerNavigationListController {},
        title     : options["#{facet}Title"] or facet.toUpperCase()
        items     : (
          title   : item.title
          type    : type
          action  : facet
        )  for own type, item of options["#{facet}s"]

      @["#{facet}Controller"] = controller

      if controller.getData().items.length > 1
        controller.on 'NavItemReceivedClick', (item)=>
          @state[item.action] = item.type
          @facetChange()
        view.addSubView controller.getView()

    view.addSubView new HelpBox @getOptions().help

  highlight:(filterName, sortName)->
    @facetTypes.forEach (facetType)=>
      controller = @["#{facetType}Controller"]
      for item in controller.itemsOrdered
        {type, action} = item.getData()
        typeMatches = switch action
          when 'filter' then filterName is type
          when 'sort'   then sortName is type
        isSelectedItem = typeMatches and controller.itemsOrdered.length > 1
        controller.selectItem item  if isSelectedItem