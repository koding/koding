kd              = require 'kd'
AvatarView      = require 'app/commonviews/avatarviews/avatarview'
getNick         = require 'app/util/nick'
ProfileTextView = require 'app/commonviews/linkviews/profiletextview'

###*
 * The purpose of this class is to prevent users
 * going to Profile pages when clicked. Instead of doing anything
 * It's gonna emit an event to its delegator when it's clicked.
 *
 * @class IDEChatMessageParticipantAvatar
 * @extends AvatarView
###
module.exports = class IDEChatMessageParticipantAvatar extends AvatarView

  INTENT_DELAY = 177
  MENU         = null

  constructor: (options = {}, data) ->

    options.bind = kd.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer = null
    @nickname    = @getOptions().origin

    @define 'nickname', => @data.profile.nickname

    @setClass 'is-hostParticipant'  if @nickname is getNick()


  click: (event) ->

    return  unless participant = @getData()

    kd.utils.stopDOMEvent event

    @emit 'ParticipantSelected', participant


  mouseEnter: ->
    kd.utils.killWait @intentTimer  if @intentTimer
    @intentTimer = kd.utils.wait INTENT_DELAY, @bound 'showMenu'


  mouseLeave: ->
    kd.utils.killWait @intentTimer  if @intentTimer
    if MENU
      @intentTimer = kd.utils.wait INTENT_DELAY, MENU.bound 'destroy'


  showMenu: ->

    return  if @nickname is getNick()
    return  if MENU and MENU.getOptions().nickname is @nickname

    MENU.destroy()  if MENU

    { appManager } = kd.singletons
    items          = {}

    items['ProfileText'] =
      type : 'customView'
      view : new ProfileTextView {}, @getData()

    appManager.tell 'IDE', 'getCollaborationData', (data) =>
      appManager.tell 'IDE', 'hasParticipantWithAudio', @nickname, (hasAudio) =>
        if hasAudio
          items['Unmute'] =
            title    : 'Unmute'
            callback : =>
              MENU?.destroy()
              appManager.tell 'IDE', 'unmuteParticipant', @nickname

        if data.amIHost
          items['Kick'] =
            title    : 'Kick'
            callback : =>
              MENU?.destroy()
              appManager.tell 'IDE', 'kickParticipant', @getData()

        if data.amIHost or hasAudio
          items['ProfileText'].separator = yes

        menuWidth = 172
        MENU = new kd.ContextMenu
          bind     : 'mouseenter mouseleave'
          nickname : @nickname
          cssClass : 'dark statusbar-files'
          delegate : this
          x        : @getX()
          y        : @getY()
          offset   : { top: 35, left: -78 }
          arrow    : { placement: 'top', margin: menuWidth / 2 }
          mouseenter : =>
            kd.utils.killWait @intentTimer  if @intentTimer
          mouseleave : =>
            kd.utils.killWait @intentTimer  if @intentTimer
            kd.utils.wait INTENT_DELAY, MENU.bound 'destroy'
        , items

        MENU.once 'KDObjectWillBeDestroyed', => MENU = null




