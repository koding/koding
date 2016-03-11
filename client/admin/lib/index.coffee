kd                         = require 'kd'
AppController              = require 'app/appcontroller'

LogsView                   = require './views/logs'
AdminAPIView               = require './views/api/adminapiview'
AdminAppView               = require './views/customviews/adminappview'
TeamInviteView             = require './views/koding-admin/teaminviteview'
TeamManageView             = require './views/koding-admin/teammanageview'
AdminMembersView           = require './views/members/adminmembersview'
AdminResourcesView         = require './views/resources/adminresourcesview'
AdministrationView         = require './views/koding-admin/administrationview'
CustomViewsManager         = require './views/customviews/customviewsmanager'
TopicModerationView        = require './views/moderation/topicmoderationview'
OnboardingAdminView        = require './views/onboarding/onboardingadminview'
AdminInvitationsView       = require './views/invitations/admininvitationsview'
GroupPermissionsView       = require './views/permissions/grouppermissionsview'
GroupPlanBillingView       = require './views/plan-billing/groupplanbillingview'
GroupsBlockedUserView      = require './views/members/groupsblockeduserview'
GroupGeneralSettingsView   = require './views/general/groupgeneralsettingsview'
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
        { slug : 'General',        title : 'General',           viewClass : GroupGeneralSettingsView, role: 'member' }
        { slug : 'Members',        title : 'Members',           viewClass : AdminMembersView         }
        { slug : 'Invitations',    title : 'Invitations',       viewClass : AdminInvitationsView     }
      # { slug : 'Permissions',    title : 'Permissions',       viewClass : GroupPermissionsView     }

        { slug : 'APIAccess',      title : 'API Access',        viewClass : AdminAPIView             }
        { slug : 'Resources',      title : 'Resources',         viewClass : AdminResourcesView       , beta: yes }
        { slug : 'Logs',           title : 'Team Logs',         viewClass : LogsView                 , beta: yes }
        # { slug : 'Plan-Billing',   title : 'Plan & Billing',    viewClass : GroupPlanBillingView     }
      ]
    koding     :
      title    : 'Koding Administration'
      items    : [
        { slug : 'TeamManage',     title : 'Manage teams',      viewClass : TeamManageView           }
        { slug : 'Blocked',        title : 'Blocked Users',     viewClass : GroupsBlockedUserView    }
        { slug : 'Widgets',        title : 'Custom Views',      viewClass : CustomViewsManager       }
        { slug : 'Onboarding',     title : 'Onboarding',        viewClass : OnboardingAdminView      }
        { slug : 'Moderation',     title : 'Topic Moderation',  viewClass : TopicModerationView      }
        { slug : 'Administration', title : 'Administration',    viewClass : AdministrationView       }
        { slug : 'TeamInvite',     title : 'Invite teams',      viewClass : TeamInviteView           }
      ]


  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view  ?= new AdminAppView
      title        : 'Team Settings'
      cssClass     : 'AppModal AppModal--admin team-settings'
      width        : 1000
      height       : '90%'
      overlay      : yes
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
        kd.singletons.router.handleRoute "/#{@options.name}"


  checkRoute: (route) -> /^\/Admin.*/.test route


  loadView: (modal) ->

    modal.once 'KDObjectWillBeDestroyed', =>

      return  if modal.dontChangeRoute

      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) => not @checkRoute route
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()


  fetchNavItems: (cb) -> cb NAV_ITEMS
