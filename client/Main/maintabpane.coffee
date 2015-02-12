class MainTabPane extends KDTabPaneView

  constructor:(options, data)->

    @id        or= options.id
    options.type = options.behavior

    super options, data

  show: ->

    super

    KD.utils.defer => window.scrollTo 0, @lastScrollTops.window


  hide: ->

    return  unless @active

    @lastScrollTops.window = window.scrollY

    super
