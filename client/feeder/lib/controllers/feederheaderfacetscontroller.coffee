kd = require 'kd'
KDView = kd.View
KDViewController = kd.ViewController
HeaderNavigationController = require './headernavigationcontroller'
isLoggedIn = require 'app/util/isLoggedIn'


module.exports = class FeederHeaderFacetsController extends KDViewController

  constructor:(options, data)->
    options.view or= new KDView cssClass: 'header-facets'
    super
    # the order of these facetTypes is the order they'll be displayed in
    @facetTypes = ['filter', 'sort']
    @state = {}
    @current

  facetChange:-> kd.getSingleton('router').handleQuery @state

  loadView:(mainView)->

    options = @getOptions()

    @facetTypes.forEach (facet)=>

      controller = new HeaderNavigationController
        delegate  : mainView
      ,
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
        # view.addSubView controller.getView()

    # view.addSubView new HelpBox @getOptions().help

  highlight:(filterName, sortName)->
    @facetTypes.forEach (facetType)=>
      controller = @["#{facetType}Controller"]
      for item in controller.getData().items
        {type, action} = item
        typeMatches = switch action
          when 'filter' then filterName is type
          when 'sort'   then sortName   is type
        if typeMatches
          controller.selectItem item
