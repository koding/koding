class DashboardAppController extends AppController

  KD.registerAppClass this,
    name         : "Dashboard"
    route        : "/Dashboard"
    behavior     : "hideTabs"
    hiddenHandle : yes

  constructor:(options={},data)->

    options.view = new DashboardAppView

    super options, data
