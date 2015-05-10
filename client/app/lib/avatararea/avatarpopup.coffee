$ = require 'jquery'
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
KDView = kd.View


module.exports = class AvatarPopup extends KDView

  constructor: (options = {}, data)->

    options.cssClass = kd.utils.curry 'avatararea-popup', options.cssClass

    super options, data

    @addSubView @avatarPopupContent = new KDView cssClass : 'content'

    @listenWindowResize()


  show:->

    { mainController, windowController } = kd.singletons
    kd.utils.killWait @loaderTimeout
    @_windowDidResize()
    windowController.addLayer this
    mainController.emit 'AvatarPopupIsActive'
    @setClass 'active'

    return this


  hide:->

    { mainController } = kd.singletons
    mainController.emit 'AvatarPopupIsInactive'
    @unsetClass 'active'

    return this


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
