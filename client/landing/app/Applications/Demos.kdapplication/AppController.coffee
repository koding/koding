class DemosAppController extends AppController

  KD.registerAppClass this,
    name         : "Demos"
    route        : "/Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->
    mainView.addSubView new KDHeaderView
      title : 'Demo App'

    mainView.addSubView new KDCustomHTMLView
      partial : 'Hello World!'
