class AppsMainView extends KDView

  constructor:(options = {}, data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    @header     = new HeaderViewSection
      type      : "big"
      title     : "App Catalog"

    @kiteButton = new KDButtonView
      cssClass  : "new-kite"
      title     : "Create New Kite"
      cssClass  : "solid mini green kite-button"
      callback  : -> new CreateKiteModal

    @header.addSubView @kiteButton
    @addSubView @header
