class AppsMainView extends KDView

  constructor:(options = {}, data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    @addSubView header = new HeaderViewSection
      type  : "big"
      title : "App Catalog"

  showContentDisplay:(content,contentType)->
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown",contentDisplay

  _windowDidResize:()=>
