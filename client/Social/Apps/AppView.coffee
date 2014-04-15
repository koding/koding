class AppsMainView extends KDView

  constructor:(options = {}, data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    @header = new HeaderViewSection
      type  : "big"
      title : "App Catalog"

    @addSubView @header