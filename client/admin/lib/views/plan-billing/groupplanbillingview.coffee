kd              = require 'kd'
KDView          = kd.View
KDTabView       = kd.TabView
KDTabPaneView   = kd.TabPaneView

GroupTeamsPlan    = require './groupteamsplan'
GroupBillingInfo  = require './groupbillinginfo'
GroupUsage        = require './groupusage'

AdminSubTabHandleView = require 'admin/views/customviews/adminsubtabhandleview'


module.exports = class GroupPlanBillingView extends KDView

  PANE_NAMES_BY_ROUTE =
    'Teams-Plan'    : 'Teams Plan'
    'Billing-Info'  : 'Billing Info'
    'Usage'         : 'Usage'


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'plan-biling-view', options.cssClass

    super options, data

    @createTabView()


  createTabView: ->

    rootPath = '/Admin/Plan-Billing'

    @addSubView @tabView = new KDTabView
      hideHandleCloseIcons : yes
      tabHandleClass       : AdminSubTabHandleView

    @tabView.addPane teamsTabView   = new KDTabPaneView
      name    : PANE_NAMES_BY_ROUTE['Teams-Plan']
      route   : "#{rootPath}/Teams-Plan"
    @tabView.addPane billingView    = new KDTabPaneView
      name    : PANE_NAMES_BY_ROUTE['Billing-Info']
      route   : "#{rootPath}/Billing-Info"
    @tabView.addPane usageView      = new KDTabPaneView
      name    : PANE_NAMES_BY_ROUTE['Usage']
      route   : "#{rootPath}/Usage"

    teamsTabView.addSubView @teamsPlan    = new GroupTeamsPlan
    billingView.addSubView  @billingInfo  = new GroupBillingInfo
    billingView.addSubView  @usage        = new GroupUsage

    @tabView.showPaneByIndex 0

    @on 'SubTabRequested', (action, identifier) => @tabView.showPaneByName PANE_NAMES_BY_ROUTE[action]
