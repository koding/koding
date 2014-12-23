class NavigationWorkspaceItem extends JView

  constructor: (options = {}, data) ->

    super options, data

    @init()


  init: ->

    @unsetClass 'kdview'

    { href, title } = @getData()
    href = KD.utils.groupifyLink href

    @title = new CustomLinkView { href, title }

    @unreadCount = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'count hidden'


  click: (event) ->

    # TODO: at least a KDView - DOM element check would
    # be more appropriate, fix later. ~Umut
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


  setUnreadCount: (unreadCount = 0) ->

    @count = unreadCount

    if unreadCount is 0
      @unreadCount.hide()
      @unsetClass 'unread'
    else
      @unreadCount.updatePartial unreadCount
      @unreadCount.show()
      @setClass 'unread'


  pistachio: ->
    """
    <figure></figure>
    {{> @title}}
    {{> @unreadCount}}
    """

