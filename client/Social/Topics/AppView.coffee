class TopicsMainView extends KDView

  constructor:(options = {},data)->

    options.ownScrollBars ?= yes

    super options,data

  createCommons:->

    @addSubView @header = new HeaderViewSection

    KD.getSingleton("mainController").on 'AccountChanged', @bound 'setSearchInput'
    @setSearchInput()

  setSearchInput:->
    @header.setSearchInput()  if 'read tags' in KD.config.permissions