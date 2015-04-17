kd                               = require 'kd'
AdministrationView               = require './views/administrationview'
CustomViewsManager               = require './views/customviews/customviewsmanager'
DashboardAppView                 = require './dashboardappview'
GroupGeneralSettingsView         = require './views/groupgeneralsettingsview'
GroupPaymentController           = require './controllers/grouppaymentcontroller'
GroupPermissionsView             = require './views/grouppermissionsview'
GroupProductSettingsView         = require './views/groupproductsettingsview'
GroupProductsController          = require './controllers/groupproductscontroller'
GroupsBlockedUserView            = require './views/groupsblockeduserview'
GroupsInvitationView             = require './views/groupsinvitationview'
GroupsMemberPermissionsView      = require './views/groupsmemberpermissionsview'
GroupsMembershipPolicyDetailView = require './views/groupsmembershippolicydetailview'
OnboardingDashboardView          = require './views/onboarding/onboardingdashboardview'
AppController                    = require 'app/appcontroller'
Encoder                          = require 'htmlencode'
require('./routehandler')()


module.exports = class DashboardAppController extends AppController

  @options = name : 'Dashboard'

  constructor: (options = {}, data) ->

    options.view = new DashboardAppView
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
          viewClass  : GroupsMemberPermissionsView
          lazy       : yes
          callback   : @bound 'membersViewAdded'
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
        name         : 'Membership policy'
        viewOptions  :
          viewClass  : GroupsMembershipPolicyDetailView
          lazy       : yes
          callback   : @bound 'policyViewAdded'
      # ,
      #   name         : 'Payment'
      #   viewOptions  :
      #     viewClass  : GroupPaymentSettingsView
      #     lazy       : yes
      #     callback   : @bound 'paymentViewAdded'
    ]

    if data.slug is "koding"
      @tabData.push
          name         : 'Products'
          kodingOnly   : yes
          viewOptions  :
            viewClass  : GroupProductSettingsView
            lazy       : yes
            callback   : @bound 'productViewAdded'
        ,
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
            viewClass  : OnboardingDashboardView
            lazy       : yes
        ,
          name         : 'Administration'
          kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
          viewOptions  :
            viewClass  : AdministrationView
            lazy       : yes

      # CURRENTLY DISABLED

      # ,
      #   name        : 'Vocabulary'
      #   viewOptions :
      #     viewClass : GroupsVocabulariesView
      #     lazy      : yes
      #     callback  : @vocabularyViewAdded
      # ,
      #   name        : 'Bundle'
      #   viewOptions :
      #     viewClass : GroupsBundleView
      #     lazy      : yes
      #     callback  : @bundleViewAdded


  fetchTabData: (callback) -> kd.utils.defer => callback @tabData

  membersViewAdded: (pane, view) ->
    group = view.getData()
    # pane.on 'PaneDidShow', ->
    #   view.refresh()  if pane.tabHandle.isDirty
    #   pane.tabHandle.markDirty no
    group.on 'MemberAdded', ->
      kd.log 'MemberAdded'
      # {tabHandle} = pane
      # tabHandle.markDirty()

  loadSection: ({title}) ->
    view = @getView()
    view.ready -> view.tabs.showPaneByName title

  policyViewAdded: (pane, view) ->

  paymentViewAdded: (pane, view) ->
    new GroupPaymentController { view }

  productViewAdded: (pane, view) ->
    new GroupProductsController { view }

  loadView: (mainView, firstRun = yes, loadFeed = no)->
    return unless firstRun
    @on "SearchFilterChanged", (value) =>
      return if value is @_searchValue
      @_searchValue = Encoder.XSSEncode value
      @getOptions().view.search @_searchValue
      @loadView mainView, no, yes

  handleQuery:(query={})->
    @getOptions().view.ready =>
      {q} = query
      @emit "SearchFilterChanged", q or ""


