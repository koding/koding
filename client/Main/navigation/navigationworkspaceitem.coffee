class NavigationWorkspaceItem extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    @init()


  init: ->

    data = @getData()

    @setPartial """
      <figure></figure>
      <a href='#{KD.utils.groupifyLink data.href}'>#{data.title}</a>
      <cite class='count hidden'>0</cite>
    """


  click: (event) ->

    isSettingsIconView = event.target.classList.contains 'ws-settings-icon'
    navItem            = @getDelegate()

    # if the event's target settings icon
    # do not pass the event to the delegate
    # which is navigation item itself. if it's not
    # don't do anything special and pass the event to
    # delegate, so that it can do its job. ~Umut
    if isSettingsIconView
      KD.utils.stopDOMEvent event
      @showSettingsPopup()
      return

    navItem.emit 'click', event


  showSettingsPopup: ->

    navItem     = @getDelegate()
    { x, y, w } = navItem.getBounds()

    top  = Math.max(y - 38, 0)
    left = x + w + 16

    position = { top, left }

    new WorkspaceSettingsPopup { position, delegate: navItem }

