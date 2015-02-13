class NavigationWorkspaceItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'kdlistitemview-main-nav workspace'

    super options, data # machine data is `options.machine`, workspace data is `data`

    {machine} = options
    workspace = data # to make it more sense in the following lines.
    path      = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
    href      = KD.utils.groupifyLink path
    title     = workspace.name

    @title = new CustomLinkView { href, title }

    @unreadCount = new KDCustomHTMLView
      tagName    : 'cite'
      cssClass   : 'count hidden'

    @settingsIcon = new KDCustomHTMLView

    unless workspace.isDefault
      @settingsIcon = new KDCustomHTMLView
        tagName     : 'span'
        cssClass    : 'ws-settings-icon'
        click       : @bound 'showSettingsPopup'


  showSettingsPopup: ->

    { x, y, w } = @getBounds()
    top         = Math.max y - 38, 0
    left        = x + w + 16
    position    = { top, left }

    settingsPopup = new WorkspaceSettingsPopup { position, delegate: this }
    settingsPopup.once 'WorkspaceDeleted', (wsId) =>
      @emit 'WorkspaceDeleted', wsId


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
      {{> @settingsIcon}}
      {{> @unreadCount}}
    """

