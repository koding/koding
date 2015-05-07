$ = require 'jquery'
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
KDView = kd.View


module.exports = class AvatarPopup extends KDView

  constructor:->

    super

    mainController = kd.getSingleton "mainController"
    mainController.on "accountChanged.to.loggedIn", @bound 'accountChanged'

    @_windowController = kd.getSingleton('windowController')
    @listenWindowResize()

  show:->
    kd.utils.killWait @loaderTimeout
    @_windowDidResize()
    @_windowController.addLayer this
    kd.getSingleton('mainController').emit "AvatarPopupIsActive"
    @setClass "active"
    return this

  hide:->
    kd.getSingleton('mainController').emit "AvatarPopupIsInactive"
    @unsetClass "active"
    return this

  viewAppended:->

    @setClass "avatararea-popup"
    @addSubView @avatarPopupTab = new KDView cssClass : 'tab', partial : '<span class="avatararea-popup-close"></span>'
    @setPopupListener()

    @addSubView @avatarPopupContent = new KDView cssClass : 'content hidden'
    @addSubView @notLoggedInWarning = new KDView
      height   : "auto"
      cssClass : "content sublink"
      partial  : @notLoggedInMessage or "Login required."

    @accountChanged()  if isLoggedIn()

  setPopupListener:->
    @avatarPopupTab.on 'click', (event)=> @hide()

  _windowDidResize:->
    if @listController
      {scrollView}             = @listController
      windowHeight             = $(global).height()
      avatarTopOffset          = @$().offset().top
      avatarBottomOffset       = 65
      avatarTopOffsetThreshold = 50

      return  if avatarTopOffset > avatarTopOffsetThreshold

      scrollView.$().css
        maxHeight : windowHeight - avatarBottomOffset - avatarTopOffsetThreshold

  accountChanged:->
    @notLoggedInWarning.hide()
    @avatarPopupContent.show()
