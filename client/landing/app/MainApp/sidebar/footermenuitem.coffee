class FooterMenuItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tooltip = switch data.title.toLowerCase()
      when "chat"
        title   : "Chat"
        gravity : "se"
        offset  : -3
      when "about"
        title : "About Koding"
        offset  : -3
      when "help"
        title   : "Instructions Book"
        gravity : "sw"
        offset  : -3

    super options, data

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
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view = new AboutView
      view.on "KDObjectWillBeDestroyed", => @aboutIsOpen = no
