kd                 = require 'kd'
AppController      = require 'app/appcontroller'
HomeAppView        = require './homeappview'
HomeUtilitiesView  = require './utilities'
HomeTeamView       = require './team'
HomeAccount     = require './account'

do require './routehandler'

module.exports = class HomeAppController extends AppController

  @options     =
    name       : 'Home'
    background : yes

  NAV_ITEMS  = [
    { title : 'Welcome',          viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'Stacks',           viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'My Team',          viewClass : HomeTeamView,      role: 'member' }
    { title : 'Koding Utilities', viewClass : HomeUtilitiesView, role: 'member' }
    { title : 'Support',          viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'Logout',           viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'My Account',       viewClass : HomeAccount,       role: 'member' }
  ]


  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view  ?= new HomeAppView { tabData: { items: NAV_ITEMS } }, data

    super options, data


  checkRoute: (route) -> /^\/Home.*/.test route

  openSection: (args...) -> @mainView.ready => @openSection_ args...

  openSection_: (section, query, action, identifier) ->

    targetPane = null
    @mainView.tabs.panes.forEach (pane) ->
      paneAction = pane.getOption 'action'
      paneSlug   = kd.utils.slugify pane.getOption 'title'

      if identifier and action is paneAction
        targetPane = pane
      else if paneSlug is kd.utils.slugify section
        targetPane = pane

    return kd.singletons.router.handleRoute "/#{@options.name}"  unless targetPane

    @mainView.tabs.showPane targetPane
    targetPaneView = targetPane.getMainView()

    if identifier
      targetPaneView.handleIdentifier? identifier, action
    else
      targetPaneView.handleAction? action

    return  unless identifier and action

    targetPaneView.emit 'SubTabRequested', action, identifier
    { parentTabTitle } = targetPane.getOptions()

    return  unless parentTabTitle

    for handle in @getView().tabs.handles
      if handle.getOption('title') is parentTabTitle
        handle.setClass 'active'


  loadView: (modal) ->

    modal.once 'KDObjectWillBeDestroyed', =>

      return  if modal.dontChangeRoute

      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) => not @checkRoute route
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()


  fetchNavItems: (cb) -> cb NAV_ITEMS
