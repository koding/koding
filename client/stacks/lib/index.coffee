kd                         = require 'kd'
AppController              = require 'app/appcontroller'
StackCatalogModalView      = require './views/customviews/stackcatalogmodalview'

YourStacksView             = require 'app/environment/yourstacksview'
MyStackTemplatesView       = require './views/stacks/my/mystacktemplatesview'
GroupStackTemplatesView    = require './views/stacks/group/groupstacktemplatesview'

require('./routehandler')()

module.exports = class StacksAppController extends AppController

  @options     =
    name       : 'Stacks'
    background : yes

  NAV_ITEMS    =
    teams      :
      title    : 'Stack Catalog'
      items    : [
        { slug : 'Your-Stacks',   title : 'Your Stacks',            viewClass : YourStacksView }
        { slug : 'My-Stacks',     title : 'My Stack Templates',     viewClass : MyStackTemplatesView }
        { slug : 'Group-Stacks',  title : 'Group Stack Templates',  viewClass : GroupStackTemplatesView }
      ]


  constructor: (options = {}, data) ->

    data         or= kd.singletons.groupsController.getCurrentGroup()
    options.view   = new StackCatalogModalView
      title        : 'Stack Catalog'
      cssClass     : 'AppModal AppModal--admin StackCatalogModal team-settings'
      width        : 1000
      height       : '90%'
      overlay      : yes
      overlayClick : no
      tabData      : NAV_ITEMS
    , data

    super options, data


  openSection: (section, query, action, identifier) ->

    targetPane = null

    @mainView.ready =>
      @mainView.tabs.panes.forEach (pane) ->
        paneAction = pane.getOption 'action'
        paneSlug   = pane.getOption 'slug'

        if identifier and action is paneAction
          targetPane = pane
        else if paneSlug is section
          targetPane = pane

      if targetPane
        @mainView.tabs.showPane targetPane
        targetPaneView = targetPane.getMainView()
        if identifier
          targetPaneView.handleIdentifier? identifier, action
        else
          targetPaneView.handleAction? action

        if identifier or action
          targetPaneView.emit 'SubTabRequested', action, identifier
          { parentTabTitle } = targetPane.getOptions()

          if parentTabTitle
            for handle in @getView().tabs.handles
              if handle.getOption('title') is parentTabTitle
                handle.setClass 'active'
      else
        kd.singletons.router.handleRoute '/Stacks'


  loadView: (modal) ->

    modal.once 'KDObjectWillBeDestroyed', ->
      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) -> not /^\/Stacks.*/.test(route)
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()

  fetchNavItems: (cb) -> cb NAV_ITEMS
