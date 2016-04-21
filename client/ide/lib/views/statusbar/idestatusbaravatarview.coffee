kd                          = require 'kd'
KDContextMenu               = kd.ContextMenu
FSHelper                    = require 'app/util/fs/fshelper'
AvatarView                  = require 'app/commonviews/avatarviews/avatarview'
IDEChatHeadWatchItemView    = require './idechatheadwatchitemview'
IDEChatHeadReadOnlyItemView = require './idechatheadreadonlyitemview'
IDELayoutManager            = require '../../workspace/idelayoutmanager'
getFullnameFromAccount      = require 'app/util/getFullnameFromAccount'


module.exports = class IDEStatusBarAvatarView extends AvatarView

  INTENT_DELAY = 177
  MENU         = null

  constructor: (options = {}, data) ->

    options.bind = kd.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer   = null
    @nickname      = @getOptions().origin
    { appManager } = kd.singletons

    appManager.tell 'IDE', 'getCollaborationData', (collaborationData) =>

      { watchMap } = collaborationData
      isWatching  = watchMap.indexOf(@nickname) > -1

      @setClass 'watching'  if isWatching


  click: (event) ->

    kd.utils.stopDOMEvent event
    @showMenu()

    return no

  mouseEnter: -> @intentTimer = kd.utils.wait INTENT_DELAY, @bound 'showMenu'

  mouseLeave: -> kd.utils.killWait @intentTimer  if @intentTimer

  showMenu: ->

    { nickname, amIHost } = @getOptions()

    return  if MENU and nickname is @nickname

    @once 'DestroyMenu', -> MENU?.destroy()

    MENU?.destroy()

    { appManager } = kd.singletons
    { frontApp }   = appManager
    { rtm }        = frontApp
    menuItems      = {}
    fullName       = getFullnameFromAccount @getData()
    disabled       = 'disabled'
    menuWidth      = 150

    if @hasRequest
      menuWidth = 325
      type      = 'customView'
      view      = new kd.CustomHTMLView
        cssClass: 'permission-row'
        partial : "#{fullName} is asking permission to make changes."

      menuItems[fullName] = { type, disabled, view }
    else
      menuItems[fullName] = { title: fullName, disabled }

    if amIHost
      menuItems.separator = { type: 'separator' }

    if @hasRequest
      type = 'customView'
      view = @createPermissionRequestMenuItem()

      menuItems.actions = { type, view }

    else if amIHost
      permission = rtm.getFromModel('permissions').get @nickname

      if permission is 'edit'
        menuItems['Revoke Permission'] =
          title    : 'Revoke Permission'
          callback : =>
            MENU?.destroy()
            frontApp.revokePermission @nickname

      else if permission is 'read'
        menuItems['Make Presenter'] =
          title    : 'Make Presenter'
          callback : =>
            MENU?.destroy()
            frontApp.approvePermissionRequest @nickname

      menuItems.Kick =
        title     : 'Kick'
        callback  : =>
          MENU?.destroy()
          appManager.tell 'IDE', 'kickParticipant', @getData()

    MENU = new KDContextMenu
      nickname    : @nickname
      cssClass    : 'dark IDE-StatusBarContextMenu'
      menuWidth   : menuWidth
      delegate    : this
      x           : @getX()
      y           : @getY()
      offset      :
        top       : -5000
        left      : -82
      arrow       :
        placement : 'bottom'
        margin    : menuWidth / 2
    , menuItems


    kd.utils.wait 200, =>
      h = MENU.getHeight()
      w = MENU.getWidth()
      top  = -h - 10
      left = @getWidth() / 2 - w / 2 - 4 # for an unknown reason - SY
      MENU.setOption 'offset', { left, top }
      MENU.positionContextMenu()

    MENU.once 'KDObjectWillBeDestroyed', -> MENU = null


  createWatchToggle: (menuItems, isWatching) ->

    return  unless menuItems
    return  if @hasClass 'offline'

    menuItems.Watch =
      type          : 'customView'
      view          : new IDEChatHeadWatchItemView
        isWatching  : isWatching
        delegate    : this


  createReadOnlyToggle: (menuItems, permission) ->

    return  unless menuItems
    return  if @hasClass 'offline'

    menuItems.ReadOnly =
      type             : 'customView'
      view             : new IDEChatHeadReadOnlyItemView
        permission     : permission
        delegate       : this


  setWatchState: (state) ->

    @toggleClass 'watching'
    methodName = if state then 'watchParticipant' else 'unwatchParticipant'

    kd.singletons.appManager.tell 'IDE', methodName, @nickname

    if state
      kd.singletons.appManager.tell 'IDE', 'showConfirmToSyncLayout', @nickname


  setReadOnlyState: (state) ->

    permission = if state then 'read' else 'edit'
    methodName = 'setParticipantPermission'

    kd.singletons.appManager.tell 'IDE', methodName, @nickname, permission


  destroy: ->

    MENU?.destroy()

    super


  showRequestPermissionView: ->

    @hasRequest = yes
    @showMenu()


  createPermissionRequestMenuItem: (item, e) ->

    return new kd.CustomHTMLView
      cssClass: 'permission-row'
      partial : '''
        <a href="#" class="deny">DENY</a> -
        <a href="#" class="grant">GRANT PERMISSION</a>
      '''
      click   : (e) =>
        { classList } = e.target
        frontApp      = kd.singletons.appManager.getFrontApp()

        if isDenied = classList.contains 'deny'
          frontApp.denyPermissionRequest @nickname
        else if isApproved = classList.contains 'grant'
          frontApp.approvePermissionRequest @nickname

        if isDenied or isApproved
          @hasRequest = null
          MENU?.destroy()
