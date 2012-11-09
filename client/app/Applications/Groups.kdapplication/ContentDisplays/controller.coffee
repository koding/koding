class ContentDisplayControllerGroups extends KDViewController
  constructor:(options = {}, data)->

    options.view or= mainView = new KDView cssClass : 'apps content-display'

    super options, data

  loadView:(mainView)->

    group = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "<span>&laquo;</span> Back"
      attributes  :
        href      : "#"
      click       : (event)->
        event.stopPropagation()
        event.preventDefault()
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView

    contentDisplayController = @getSingleton "contentDisplayController"

    # mainView.addSubView wrapperView = new AppViewMainPanel {}, app

    mainView.addSubView appView = new GroupView
      cssClass : "profilearea clearfix"
      delegate : mainView
    , group

    # mainView.addSubView appView = new AppDetailsView
    #   cssClass : "info-wrapper"
    #   delegate : mainView
    # , app


