kd                        = require 'kd'
AppController             = require 'app/appcontroller'

AdminAppView              = require './adminappview'
AdminMembersView          = require './views/members/adminmembersview'
AdministrationView        = require './views/administrationview'
CustomViewsManager        = require './views/customviews/customviewsmanager'
GroupStackSettings        = require './views/groupstacksettings'
OnboardingAdminView       = require './views/onboarding/onboardingadminview'
GroupPermissionsView      = require './views/grouppermissionsview'
GroupsInvitationView      = require './views/groupsinvitationview'
GroupsBlockedUserView     = require './views/groupsblockeduserview'
GroupGeneralSettingsView  = require './views/groupgeneralsettingsview'

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
        { slug : 'Members',        title : 'Members',           viewClass : AdminMembersView }
      # { slug : 'Policies',       title : 'Membership Policy', viewClass : kd.View }
        { slug : 'Invitations',    title : 'Invitations',       viewClass : GroupsInvitationView }
        { slug : 'Permissions',    title : 'Permissions',       viewClass : GroupPermissionsView }
        { slug : 'Stacks',         title : 'Compute Stacks',    viewClass : GroupStackSettings }
      ]
    koding     :
      title    : 'Koding Administration'
      items    : [
        { slug : 'Blocked',        title : 'Blocked Users',     viewClass : GroupsBlockedUserView }
        { slug : 'Widgets',        title : 'Custom Views',      viewClass : CustomViewsManager }
        { slug : 'Onboarding',     title : 'Onboarding',        viewClass : OnboardingAdminView }
        { slug : 'Administration', title : 'Administration',    viewClass : AdministrationView }
      ]


  constructor: (options = {}, data) ->

    options.view = new kd.ModalView
      title      : 'Team Dashboard'
      cssClass   : 'AppModal AppModal--admin'
      width      : 1000
      height     : 600
      overlay    : yes

    data       or= kd.singletons.groupsController.getCurrentGroup()

    super options, data


  openSection: (section, query) ->

    @mainView.ready =>
      unless @mainView.tabs.showPaneByName section
        kd.singletons.router.handleRoute "/Admin/Settings"


  loadView: (modal) ->

    modal.addSubView @mainView = new AdminAppView
      tabData: NAV_ITEMS
    , @getData()
