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
        KD.getSingleton("kodingAppsController").updateAllApps()
        @hide()

    @updateAppsButton.hide()
    @updateAppsButton.on "UpdateView", (filter)->
      @hide()  unless filter is 'updates'
      if filter is 'updates'
        appsController = KD.getSingleton("kodingAppsController")
        appsController.fetchUpdateAvailableApps (res, apps)=>
          unless apps?.length then @hide() else @show()

    @addSubView header