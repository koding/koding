kd                         = require 'kd'
AppController              = require 'app/appcontroller'
AdminAppView               = require './adminappview'
AdminMembersView           = require './views/members/adminmembersview'
AdministrationView         = require './views/administrationview'
CustomViewsManager         = require './views/customviews/customviewsmanager'
TopicModerationView        = require './views/moderation/topicmoderationview'
GroupStackSettings         = require './views/groupstacksettings'
OnboardingAdminView        = require './views/onboarding/onboardingadminview'
AdminInvitationsView       = require './views/invitations/admininvitationsview'
GroupPermissionsView       = require './views/grouppermissionsview'
GroupsBlockedUserView      = require './views/groupsblockeduserview'
AdminIntegrationsView      = require './views/integrations/adminintegrationsview'
GroupGeneralSettingsView   = require './views/groupgeneralsettingsview'
AdminIntegrationParentView = require './views/integrations/adminintegrationparentview'


require('./routehandler')()


module.exports = class AdminAppController extends AppController

  @options     =
    name       : 'Admin'
    background : yes

  NAV_ITEMS    =
    teams      :
      title    : 'Team Settings'
      items    : [
        { slug : 'Settings',       title : 'Settings',          viewClass : GroupGeneralSettingsView }
        { slug : 'Members',        title : 'Members',           viewClass : AdminMembersView         }
        { slug : 'Invitations',    title : 'Invitations',       viewClass : AdminInvitationsView     }
        { slug : 'Permissions',    title : 'Permissions',       viewClass : GroupPermissionsView     }
        {
          slug      : 'Integrations'
          title     : 'Integrations'
          viewClass : AdminIntegrationsView,
          subTabs   : [
            { title : 'Add',        action: 'Add',              viewClass : AdminIntegrationParentView }
            { title : 'Configure',  action: 'Configure',        viewClass : AdminIntegrationParentView }
          ]
        }
        { slug : 'Stacks',         title : 'Compute Stacks',    viewClass : GroupStackSettings       }
      ]
    koding     :
      title    : 'Koding Administration'
      items    : [
        { slug : 'Blocked',        title : 'Blocked Users',     viewClass : GroupsBlockedUserView    }
        { slug : 'Widgets',        title : 'Custom Views',      viewClass : CustomViewsManager       }
        { slug : 'Onboarding',     title : 'Onboarding',        viewClass : OnboardingAdminView      }
        { slug : 'Moderation',     title : 'Topic Moderation',  viewClass : TopicModerationView      }
        { slug : 'Administration', title : 'Administration',    viewClass : AdministrationView       }
      ]


  constructor: (options = {}, data) ->

    data       or= kd.singletons.groupsController.getCurrentGroup()
    options.view = new AdminAppView
      title      : 'Team Dashboard'
      cssClass   : 'AppModal AppModal--admin'
      width      : 1000
      height     : '100%'
      overlay    : yes
      tabData    : NAV_ITEMS
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
      else
        kd.singletons.router.handleRoute '/Admin/Settings'


  loadView: (modal) ->

    modal.once 'KDObjectWillBeDestroyed', ->
      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) -> not /^\/Admin.*/.test(route)
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()
