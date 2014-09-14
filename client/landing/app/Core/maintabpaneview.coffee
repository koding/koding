class MainTabPane extends KDTabPaneView

  constructor:(options, data)->

    @id        or= options.id
    options.type = options.behavior

    super options, data

  show: ->

    super

    KD.utils.defer =>
      {body, documentElement}   = document
      documentElement.scrollTop = @lastScrollTops.window
      body.scrollTop            = @lastScrollTops.body


  hide: ->

    return  unless @active

    {body, documentElement} = document
    @lastScrollTops.window  = documentElement.scrollTop
    @lastScrollTops.body    = body.scrollTop

    super