kd                  = require 'kd'
AppController       = require 'app/appcontroller'
HomeAppView         = require './homeappview'
HomeAccount         = require './account'
HomeUtilities       = require './utilities'
HomeMyTeam          = require './myteam'
HomeTeamBilling     = require './billing'
HomePaymentHistory  = require './paymenthistory'
HomeStacks          = require './stacks'
HomeBuildLogs = require './buildlogs'

do require './routehandler'

module.exports = class HomeAppController extends AppController

  @options     =
    name       : 'Home'
    background : yes

  TABS = [
    { title : 'Stacks', viewClass : HomeStacks, role: 'member' }
    { title : 'My Team', viewClass : HomeMyTeam, role: 'member' }
    { title : 'Team Billing', viewClass : HomeTeamBilling }
    { title : 'Payment History', viewClass : HomePaymentHistory }
    { title : 'Koding Utilities', viewClass : HomeUtilities, role: 'member' }
    { title : 'My Account', viewClass : HomeAccount, role: 'member' }
    { title : 'Build Logs', viewClass : HomeBuildLogs, role: 'member' }
  ]


  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view  ?= new HomeAppView { tabData: { items: TABS } }, data

    super options, data


  checkRoute: (route) -> /^\/(?:Home).*/.test route

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
    else if action
      targetPaneView.handleAction? action
    else
      @doOnboarding targetPane

    unless identifier and action
      return targetPaneView.handleSection?()  unless action


  loadView: (modal) ->

    modal.once 'KDObjectWillBeDestroyed', =>

      return  if modal.dontChangeRoute

      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) => not @checkRoute route
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()


  fetchNavItems: (cb) -> cb TABS


  doOnboarding: (pane) ->

    { onboarding }  = kd.singletons
    onboardingEvent = @getOnboardingEventByPane pane
    if onboardingEvent
      onboarding.run onboardingEvent, yes
    else
      onboarding.refresh()


  getOnboardingEventByPane: (pane) ->

    slug = kd.utils.slugify pane.getOption 'title'

    switch slug
      when 'stacks'           then 'StacksViewed'
      when 'my-team'          then 'MyTeamViewed'
      when 'team-billing'     then 'TeamBillingViewed'
      when 'koding-utilities' then 'KodingUtilitiesViewed'
      when 'my-account'       then 'MyAccountViewed'
