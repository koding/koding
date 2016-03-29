kd              = require 'kd'
AppController   = require 'app/appcontroller'
HomeAppView     = require './homeappview'
HomeAccount     = require './account'
HomeUtilities   = require './utilities'
HomeMyTeam      = require './myteam'
HomeTeamBilling = require './billing'
HomeWelcome     = require './welcome'

do require './routehandler'

module.exports = class HomeAppController extends AppController

  @options     =
    name       : 'Home'
    background : yes

  TABS = [
    { title : 'Welcome',          viewClass : HomeWelcome,       role: 'member' }
    { title : 'Stacks',           viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'Virtual Machines', viewClass : kd.CustomHTMLView, role: 'member' }
    { title : 'My Team',          viewClass : HomeMyTeam,        role: 'member' }
    { title : 'Team Billing',     viewClass : HomeTeamBilling                   }
    { title : 'Koding Utilities', viewClass : HomeUtilities,     role: 'member' }
    { title : 'My Account',       viewClass : HomeAccount,       role: 'member' }
  ]


  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view  ?= new HomeAppView { tabData: { items: TABS } }, data

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


  fetchNavItems: (cb) -> cb TABS
