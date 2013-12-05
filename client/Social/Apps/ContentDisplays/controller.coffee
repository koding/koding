class ContentDisplayControllerApps extends KDViewController

  constructor:(options = {}, data)->

    options.view or= mainView = new KDView cssClass : 'apps content-display'

    super options, data

  loadView:(mainView)->

    app = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    mainView.addSubView appView = new AppView
      cssClass : "profilearea clearfix"
      delegate : mainView
    , app

    mainView.addSubView appView = new AppDetailsView
      cssClass : "info-wrapper"
      delegate : mainView
    , app
