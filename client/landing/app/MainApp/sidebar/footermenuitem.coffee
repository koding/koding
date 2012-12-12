class FooterMenuItem extends KDListItemView

  constructor:(options = {}, data)->

    super options, data

    @icon = new KDCustomHTMLView
      tagName : 'span'
      tooltip : switch data.title.toLowerCase()
        when "chat"
          title   : "Chat"
          placement : 'top'
          direction : 'left'
          offset  :
            top   : 3
            left : -5
        when "about"
          title : "About Koding"
          placement : 'top'
          direction : 'center'
          offset  :
            top   : 3
            left  : -8
        when "help"
          title   : "Instructions Book"
          placement : 'top'
          direction : 'right'
          offset  :
            top   : 3

    @setClass "#{@utils.slugify @getData().title.toLowerCase()}"

  mouseDown:(event)->

    cb = @getData().callback
    cb.call @ if cb

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
     {{> @icon}}
    """

  showAboutDisplay:->

    if not @aboutIsOpen
      @aboutIsOpen             = yes
      contentDisplayController = @getSingleton "contentDisplayController"
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view = new AboutView
      view.on "KDObjectWillBeDestroyed", => @aboutIsOpen = no
