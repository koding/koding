class MainTabPane extends KDTabPaneView
  constructor:(options,data)->
    @id or= options.id
    super
  
  setMainView:(view)->
    @mainView = view
    @addSubView view
  
  getMainView:()->
    @mainView
