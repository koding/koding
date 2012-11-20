class FeederFacetsController extends KDViewController
  constructor:(options, data)->
    options.view or= new KDView cssClass: 'common-inner-nav'
    super
    @facetTypes = ['sort', 'filter']
    @state = {}

  onfacetchange:->
    console.log 'onfacetchange'
    KD.getSingleton('router').handleQuery @state

  loadView:(mainView)->
    options = @getOptions()
    view = @getView()

    @facetTypes.forEach (facet)=>
      console.log facet
      return  if facet is "everything"

      @["#{facet}Controller"] =
      controller = new CommonInnerNavigationListController {},
        title     : options["#{facet}Title"] or facet.toUpperCase()
        items     : (
          title   : item.title
          type    : type
          action  : facet
        )  for own type, item of options["#{facet}s"]

      if controller.getData().items.length > 1
        controller.on 'NavItemReceivedClick', (item)=>
          @state[item.action] = item.type
          @onfacetchange()
        view.addSubView controller.getView()

    view.addSubView new HelpBox @getOptions().help


  highlight:(facet, sortName)->
    @facetTypes.forEach (facet)=>
      controller = @["#{facet}Controller"]
      for item in controller.itemsOrdered
        isSelectedItem = item.getData().type is facet and\
                         controller.itemsOrdered.length > 1
        controller.selectItem item  if isSelectedItem