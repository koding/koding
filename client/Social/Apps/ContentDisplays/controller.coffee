class ContentDisplayControllerApps extends KDViewController

  constructor:(options = {}, data)->

    options.view or= mainView = new KDView cssClass : 'content-page appstore singleapp'

    super options, data

  loadView:(mainView)->

    mainView.addSubView appView = new AppDetailsView
      cssClass : "app-details"
      delegate : mainView
    , @getData()
