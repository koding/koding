kd                        = require 'kd'
AdminAppView              = require './adminappview'
AppController             = require 'app/appcontroller'
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

  @options =
    name       : 'Admin'
    background : yes

  constructor: (options = {}, data) ->

    options.view = new kd.ModalView
      title      : 'Team Dashboard'
      cssClass   : 'AppModal AppModal--admin'
      width      : 1000
      height     : 600
      overlay    : yes

    data       or= kd.singletons.groupsController.getCurrentGroup()

    super options, data

    @tabData = [
        name         : 'Settings'
        viewOptions  :
          viewClass  : GroupGeneralSettingsView
          lazy       : yes
      ,
        name         : 'Members'
        viewOptions  :
          viewClass  : AdminMembersView
          lazy       : yes
      ,
        name         : 'Invitations'
        viewOptions  :
          viewClass  : GroupsInvitationView
          lazy       : yes
      ,
        name         : 'Permissions'
        viewOptions  :
          viewClass  : GroupPermissionsView
          lazy       : yes
      ,
        name         : 'Stacks'
        viewOptions  :
          viewClass  : GroupStackSettings
          lazy       : yes
      ,
        name         : 'Membership policy'
        viewOptions  :
          viewClass  : kd.View
          lazy       : yes
          callback   : ->
    ]

    if data.slug is "koding"
      @tabData.push
          name         : 'Blocked users'
          kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
          viewOptions  :
            viewClass  : GroupsBlockedUserView
            lazy       : yes
        ,
          name         : 'Widgets'
          kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
          viewOptions  :
            viewClass  : CustomViewsManager
            lazy       : yes
        ,
          name         : 'Onboarding'
          kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
          viewOptions  :
            viewClass  : OnboardingAdminView
            lazy       : yes
        ,
          name         : 'Administration'
          kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
          viewOptions  :
            viewClass  : AdministrationView
            lazy       : yes


  fetchTabData: (callback) -> kd.utils.defer => callback @tabData

  loadSection: ({title}) ->
    view = @getView()
    view.ready -> view.tabs.showPaneByName title
