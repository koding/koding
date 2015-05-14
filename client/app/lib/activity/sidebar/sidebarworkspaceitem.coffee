kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView
JView = require 'app/jview'
CustomLinkView = require 'app/customlinkview'
groupifyLink = require 'app/util/groupifyLink'
WorkspaceSettingsPopup = require 'app/workspacesettingspopup'


module.exports = class SidebarWorkspaceItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'kdlistitemview-main-nav workspace'

    super options, data # machine data is `options.machine`, workspace data is `data`

    {machine} = options
    workspace = data # to make it more sense in the following lines.
    path      = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
    title     = workspace.name

    unless machine.isMine()
      if machine.isPermanent()
        path = "/IDE/#{machine.uid}/#{workspace.slug}"
      else
        path = "/IDE/#{workspace.channelId}"

    href   = groupifyLink path
    @title = new CustomLinkView { href, title }

    @unreadIndicator = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'count hidden'

    iconOptions = {}

    if not workspace.isDefault and machine.isMine()
      iconOptions =
        tagName   : 'span'
        cssClass  : 'ws-settings-icon'
        click     : @bound 'showSettingsPopup'

    @settingsIcon = new KDCustomHTMLView iconOptions


  mouseDown: (event) ->

    if @count
      ide = kd.singletons.appManager.get 'IDE'
      return  unless ide.chat
      ide.showChat()
      kd.utils.defer -> ide.chat.focus()


  showSettingsPopup: ->

    { x, y, w } = @getBounds()
    top         = Math.max y - 38, 0
    left        = x + w + 16
    position    = { top, left }

    settingsPopup = new WorkspaceSettingsPopup { position, delegate: this }
    settingsPopup.once 'WorkspaceDeleted', (wsId) =>
      @emit 'WorkspaceDeleted', wsId


  moveSettingsIconLeft : ->

    @settingsIcon.setClass 'move-left'


  resetSettingsIconPosition : ->

    @settingsIcon.unsetClass 'move-left'


  setUnreadCount: (count = 0) ->

    @unreadCount = count

    if count > 0
      @moveSettingsIconLeft()
      @unreadIndicator.updatePartial count
      @unreadIndicator.show()
      @setClass 'unread'
    else
      @resetSettingsIconPosition()
      @unreadIndicator.hide()
      @unsetClass 'unread'


  pistachio: ->
    """
      <figure></figure>
      {{> @title}}
      {{> @settingsIcon}}
      {{> @unreadIndicator}}
    """
