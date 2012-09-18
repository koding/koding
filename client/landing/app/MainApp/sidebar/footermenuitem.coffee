class FooterMenuItem extends KDListItemView

  constructor:->
    super
    @setClass "#{@utils.slugify @getData().title.toLowerCase()}"

  mouseDown:(event)->

    cb = @getData().callback
    cb.call @ if cb

  partial:->
    "<span></span>"

  showAboutDisplay:->

    if not @aboutIsOpen
      @aboutIsOpen             = yes
      contentDisplayController = @getSingleton "contentDisplayController"
      controller               = new ContentDisplayControllerAbout null, null
      contentDisplay           = controller.getView()

      contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
      contentDisplayController.on   "ContentDisplayWantsToBeHidden", => @aboutIsOpen = no
