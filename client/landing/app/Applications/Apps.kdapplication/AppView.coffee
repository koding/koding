class AppsMainView extends KDView

  constructor:(options = {}, data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    header = new HeaderViewSection
      type  : "big"
      title : "App Catalog"

    header.addSubView @updateAppsButton = new KDButtonView
      title     : "Update All"
      style     : "cupid-green update-apps-button"
      callback  : ->
        @getSingleton("kodingAppsController").updateAllApps()
        @hide()

    @updateAppsButton.hide()

    @addSubView header
