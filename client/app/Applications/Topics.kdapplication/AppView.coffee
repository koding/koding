class TopicsMainView extends KDView

  constructor:(options = {},data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    @addSubView header = new HeaderViewSection
      type  : "big"
      title : "Topics"

    header.setSearchInput()