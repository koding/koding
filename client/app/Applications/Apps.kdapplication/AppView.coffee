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
        appsController = @getSingleton "kodingAppsController"
        apps           = @getData()
        stack          = []

        delete appsController.notification

        apps.forEach (app) =>
          stack.push (callback) =>
            appsController.updateUserApp app.manifest, callback

        async.series stack

    @updateAppsButton.hide()

    @addSubView header
