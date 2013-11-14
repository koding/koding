class FooterMenuItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tooltip = switch data.title.toLowerCase()
      when "chat"
        title     : "Chat"
        direction : 'center'
        placement : 'top'
        delay     : 500
        offset    :
          top     : 5
          left    : 0
      when "about"
        title     : "About Koding"
        placement : 'top'
        direction : 'center'
        delay     : 500
        offset    :
          top     : 3
          left    : -3
      when "help"
        title     : "Instructions Book"
        placement : 'top'
        direction : 'right'
        delay     : 500
        offset    :
          top     : 3
          left    : 13

    super options, data

    @icon = new KDCustomHTMLView
      tagName : 'span'

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
    KD.getSingleton('router').handleRoute '/About'
