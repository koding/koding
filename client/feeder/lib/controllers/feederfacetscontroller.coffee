kd = require 'kd'
KDView = kd.View
KDViewController = kd.ViewController
isLoggedIn = require 'app/util/isLoggedIn'
CommonInnerNavigationListController = require 'app/commonviews/commoninnernavigationlistcontroller'
HelpBox = require 'app/commonviews/helpbox'


module.exports = class FeederFacetsController extends KDViewController

  constructor:(options = {}, data)->

    options.view or= new KDView cssClass: 'common-inner-nav'

    super options, data

    # the order of these facetTypes is the order they'll be displayed in
    @facetTypes = ['filter', 'sort']
    @state = {}

  facetChange:-> kd.getSingleton('router').handleQuery @state

  loadView:(mainView)->

    options = @getOptions()
    view = @getView()

    @facetTypes.forEach (facet)=>

      controller = new CommonInnerNavigationListController {},
        title     : options["#{facet}Title"] or facet.toUpperCase()
        items     : ((
          title   : item.title
          type    : type
          action  : facet
        ) for own type, item of options["#{facet}s"] when not item.loggedInOnly or isLoggedIn())

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
      for item in controller.getListItems()
        {type, action} = item.getData()
        typeMatches = switch action
          when 'filter' then filterName is type
          when 'sort'   then sortName is type
        isSelectedItem = typeMatches and controller.getListItems().length > 1
        controller.selectItem item  if isSelectedItem


